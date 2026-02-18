import 'dart:async';
import 'dart:convert';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/group_key_exchange.dart';
import 'package:evercrypted/core/helpers/get_random_string.dart';
import 'package:evercrypted/core/http.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';

import 'package:evercrypted/core/offline/action_queue/action_queue_service.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/core/services/socket_events_service.dart';
import 'package:evercrypted/core/socket/event_types/general_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';

import 'package:rhttp/rhttp.dart';
import 'package:rxdart/subjects.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
import '../cryptography/payload.dart';

class ChatSocket {
  ChatSocket._();
  static io.Socket? socket;
  static KyberKeyPair? keyPair;
  static String? key;
  static final ActionQueueService actionQueueService = ActionQueueService();
  static final SocketEventsService socketEventsService = SocketEventsService();
  static final AuthService authService = AuthService();

  static bool? isConnected;

  static BehaviorSubject<bool> isConnectedSubject = BehaviorSubject<bool>();
  static BehaviorSubject<bool> resetConnectionSubject = BehaviorSubject<bool>();

  static num tries = 0;

  static String _getSocketUrl() {
    // Use different URLs based on platform and debug mode
    // if (kDebugMode) {
    //   if (Platform.isAndroid) {
    //     return 'http://10.0.2.2:4000'; // Android emulator
    //   } else if (Platform.isIOS) {
    //     return 'http://localhost:4000'; // iOS simulator
    //   } else {
    //     return 'http://localhost:4000'; // Desktop/Web
    //   }
    // } else {
    //   return 'http://10.0.2.2:4000'; // Production
    //   // return 'https://test-api.evercrypted.com:8443'; // Production
    // }
    return 'https://socket.evercrypted.com';
  }

  static const channelsToListen = [
    SocketChannelTypes.chat,
    SocketChannelTypes.error,
    SocketChannelTypes.contactRequest,
    SocketChannelTypes.contact,
    SocketChannelTypes.settings,
    SocketChannelTypes.message,
    SocketChannelTypes.auth,
    SocketChannelTypes.payment,
  ];

  static initializeConnectionListener() {
    // Listen to connection status changes
    isConnectedSubject.distinct().listen((connected) async {
      if (connected) {
        // Wait for connection to stabilize and ensure key is available
        await Future.delayed(Duration(seconds: 3));

        // Double-check we're still connected and have a key
        if (isConnected == true && key != null) {
          // Process queue (includes handling messages pending key exchange)
          await actionQueueService.processQueue();
        }
      }
    });
  }

  static getAuthAndIdentifier() async {
    final identifier =
        DateTime.now().millisecondsSinceEpoch.toString() + getRandomString(32);

    late Map<String, dynamic> keys;
    try {
      keys = await authService.loginHandshake(identifier);
    } catch (e) {
      isConnected = false;
      isConnectedSubject.add(isConnected!);
      return null;
    }

    final token = await Auth.getToken;

    final otpToken = await Auth.getOtpToken;

    final cryptedToken = await encodePayload(token, keys['key'], true);

    var headers = {
      'authorization': jsonEncode(cryptedToken),
      'identifier': identifier,
    };

    if (otpToken != null) {
      final cryptedOtpToken = await encodePayload(otpToken, keys['key'], true);
      headers['otpToken'] = jsonEncode(cryptedOtpToken);
    }

    return {
      'headers': headers,
      'key': keys['key'],
    };
  }

  static getGeneralInfoAndExchangeKey() async {
    final keyCompleter = Completer<bool>();

    // Generate Kyber1024 key pair
    keyPair = EverCrypto.generateKyberKeyPair();

    final authAndIdentifier = await getAuthAndIdentifier();

    if (authAndIdentifier == null) return;

    // Get FCM token from Auth storage
    final fcmToken = await Auth.getFcmToken;

    final body = await encodePayload({
      'channel': SocketChannelTypes.general,
      'type': GeneralEventTypes.getInitialData,
      'payload': {
        'publicKey': base64Encode(keyPair!.publicKey),
        'fcmToken': fcmToken,
      }
    }, authAndIdentifier['key'], true);

    AppHttpClient.client
        .post('/socket/handle-message',
            body: HttpBody.json({
              ...body,
              'headers': authAndIdentifier['headers'],
            }))
        .then((dynamic resp) async {
      // Server responds with ciphertext for Kyber1024 decapsulation
      final serverCiphertext = resp.bodyToJson['ciphertext'];

      if (serverCiphertext != null) {
        // Decapsulate the shared secret using our secret key and server's ciphertext
        final sharedSecret = EverCrypto.kyberDecapsulate(
          base64Decode(serverCiphertext),
          keyPair!.secretKey,
        );
        key = base64Encode(sharedSecret);
      }

      if (!keyCompleter.isCompleted) {
        keyCompleter.complete(true);
      }
      if (key != null) {
        final payload = await decodePayload(
          resp.bodyToJson['crypted'],
          resp.bodyToJson['iv'],
          key,
          true,
        );
        socketEventsService.handleGeneralEvent('getInitialData', payload);

        // After establishing WebSocket encryption, trigger key exchange checks
        // This will cause the chat service to check for pending key exchanges
        // and complete the Kyber key exchange process for any chats that need it
        await _checkPendingKeyExchanges();
      }
    }).catchError((error) {
      if (error.toString().contains('Status code: 401')) {
        Auth.clearAuth();
      }
      if (!keyCompleter.isCompleted) {
        keyCompleter.complete(false);
      }
    });
    return keyCompleter.future;
  }

  static connectWS() async {
    tries = tries + 1;

    if (socket != null) {
      disconnectWS();
    }

    dynamic options = OptionBuilder().setTransports(['websocket']);

    final authAndIdentifier = await getAuthAndIdentifier();

    if (authAndIdentifier == null) return;

    options = options.setExtraHeaders(authAndIdentifier['headers']);

    io.cache.clear();
    final socketUrl = _getSocketUrl();

    socket = io.io(socketUrl, options.build());

    if (socket?.connected != true) {
      socket?.connect();
    }

    socket?.onConnect((_) async {
      socket?.clearListeners();
      await getGeneralInfoAndExchangeKey();

      // Set connection status before processing queue
      isConnected = true;
      isConnectedSubject.add(isConnected!);

      // Process queued actions immediately on connect
      await actionQueueService.processQueue();
    });

    socket?.onReconnect((data) async {
      socket?.clearListeners();
      await getGeneralInfoAndExchangeKey();

      // Set connection status before processing queue
      isConnected = true;
      isConnectedSubject.add(isConnected!);

      // Process queued actions immediately on reconnect
      await actionQueueService.processQueue();
    });

    socket?.on('disconnect', (data) {
      isConnected = false;
      isConnectedSubject.add(isConnected!);
      disconnectWS();
    });

    socket?.onError((data) {
      if (data == 'timeout') {
        isConnected = false;
        isConnectedSubject.add(isConnected!);
      } else {
        disconnectWS();
        isConnected = false;
        isConnectedSubject.add(isConnected!);
      }
    });

    socket?.onAny((channel, data) async {
      if (channel == SocketChannelTypes.error) {
        socketEventsService.handleErrorEvent(data['type'], data['payload']);
      } else {
        if (channelsToListen.contains(channel)) {
          if (channel == SocketChannelTypes.error &&
              data['message'] == 'Invalid Credentials') {
            disconnectWS();
            isConnected = false;
            isConnectedSubject.add(isConnected!);
          } else {
            dynamic payload;
            if (key != null) {
              payload = await decodePayload(
                data['crypted'],
                data['iv'],
                key,
                true,
              );
            } else {
              payload = data;
            }

            socketEventsService.handleEvent(
                channel, payload['type'], payload['payload']);
          }
        }
      }
    });

    socket?.onDisconnect((_) {
      isConnected = false;
      isConnectedSubject.add(isConnected!);
      disconnectWS();
    });
  }

  static void disconnectWS() {
    socket?.clearListeners();
    socket?.destroy();
    socket?.dispose();
    key = null;
    socket = null;
  }

  static bool _isResettingConnection = false;

  static resetConnection() async {
    // Prevent concurrent resets
    if (_isResettingConnection) {
      return;
    }
    _isResettingConnection = true;
    try {
      disconnectWS();
      await connectWS();
    } finally {
      _isResettingConnection = false;
    }
  }

  static Future<void> _checkPendingKeyExchanges() async {
    // Get all chats and trigger unified key exchange checks
    final chats = ObxInit.obx.chats.getAll();

    // Check each chat for pending key exchanges (unified approach)
    for (final chat in chats) {
      await GroupKeyExchange.ensureGroupKey(chat.uid, chat.isOneToOne);
    }
  }
}
