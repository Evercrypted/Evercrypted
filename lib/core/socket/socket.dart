import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/helpers/get_random_string.dart';
import 'package:evercrypted/core/http.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';

import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_service.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/core/services/socket_events_service.dart';
import 'package:evercrypted/core/socket/event_types/general_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:rhttp/rhttp.dart';
import 'package:rxdart/subjects.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
import '../cryptography/payload.dart';
import '../offline/action_queue/allowed_for_queue.dart';

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
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:4000'; // Android emulator
      } else if (Platform.isIOS) {
        return 'http://localhost:4000'; // iOS simulator
      } else {
        return 'http://localhost:4000'; // Desktop/Web
      }
    } else {
      return 'http://10.0.2.2:4000'; // Production
      // return 'https://test-api.evercrypted.com:8443'; // Production
    }
  }

  static const channelsToListen = [
    SocketChannelTypes.chat,
    SocketChannelTypes.error,
    SocketChannelTypes.contactRequest,
    SocketChannelTypes.contact,
    SocketChannelTypes.settings,
    SocketChannelTypes.message,
    SocketChannelTypes.auth,
  ];

  static initializeConnectionListener() {
    // Listen to connection status changes
    isConnectedSubject.distinct().listen((connected) async {
      if (connected) {
        debugPrint('ChatSocket: Connection established, processing queue');
        // Wait for connection to stabilize and ensure key is available
        await Future.delayed(Duration(seconds: 3));

        // Double-check we're still connected and have a key
        if (isConnected == true && key != null) {
          debugPrint(
              'ChatSocket: Connection verified, starting queue processing');
          // Process queue (includes handling messages pending key exchange)
          await actionQueueService.processQueue();
        } else {
          debugPrint(
              'ChatSocket: Connection lost or no key after delay, skipping queue processing');
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
      debugPrint(e.toString());
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
    // for apple push notification
    // final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final keyCompleter = Completer<bool>();

    // Generate Kyber1024 key pair
    keyPair = EverCrypto.generateKyberKeyPair();

    final authAndIdentifier = await getAuthAndIdentifier();

    if (authAndIdentifier == null) return;

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

      keyCompleter.complete(true);
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
      debugPrint('Error during getGeneralInfoAndExchangeKey: $error');
      debugPrint(error.toString());
      if (error.toString().contains('Status code: 401')) {
        Auth.clearAuth();
      }
      keyCompleter.complete(false);
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
    debugPrint('ChatSocket: Connecting to $socketUrl');
    socket = io.io(socketUrl, options.build());

    if (socket?.connected != true) {
      debugPrint('connecting');
      socket?.connect();
    }

    socket?.onConnect((_) async {
      debugPrint('connected');
      socket?.clearListeners();
      await getGeneralInfoAndExchangeKey();

      // Set connection status before processing queue
      isConnected = true;
      isConnectedSubject.add(isConnected!);

      // Process queued actions immediately on connect
      await actionQueueService.processQueue();
    });

    socket?.onReconnect((data) async {
      debugPrint('reconnected');
      socket?.clearListeners();
      await getGeneralInfoAndExchangeKey();

      // Set connection status before processing queue
      isConnected = true;
      isConnectedSubject.add(isConnected!);

      // Process queued actions immediately on reconnect
      await actionQueueService.processQueue();
    });

    socket?.on('disconnect', (data) {
      debugPrint('disconnected');
      isConnected = false;
      isConnectedSubject.add(isConnected!);
      disconnectWS();
    });

    socket?.onError((data) {
      if (data == 'timeout') {
        isConnected = false;
        isConnectedSubject.add(isConnected!);
      } else {
        debugPrint('onError: ${data is String ? data : data.toString()}');
        disconnectWS();
        isConnected = false;
        isConnectedSubject.add(isConnected!);
      }
    });

    socket?.onAny((channel, data) async {
      debugPrint('event $channel');
      debugPrint('data $data');
      if (channel == SocketChannelTypes.error) {
        debugPrint('error event');
        socketEventsService.handleErrorEvent(data['type'], data['payload']);
      } else {
        if (channelsToListen.contains(channel)) {
          if (channel == SocketChannelTypes.error &&
              data['message'] == 'Invalid Credentials') {
            debugPrint('Could not connect to socket server');
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

            debugPrint(
              'got emit to $channel - ${payload.toString()}',
            );
            socketEventsService.handleEvent(
                channel, payload['type'], payload['payload']);
          }
        } else {
          debugPrint('Unknown event: $channel with data: $data');
        }
      }
    });

    socket?.onDisconnect((_) {
      debugPrint('disconnected');
      isConnected = false;
      isConnectedSubject.add(isConnected!);
      disconnectWS();
    });
  }

  static Future<dynamic> emitWAck(String channel, String type, dynamic payload,
      {bool isFromQueue = false}) async {
    Future<int> saveActionForLater() async {
      final writingToQueueCompleter = Completer<int>();
      final action = ActionQueue(
          channel: channel,
          type: type,
          payload: json.encode(payload),
          createdAtMSE: DateTime.now().millisecondsSinceEpoch);
      final int id = obx.actionQueues.put(action);
      writingToQueueCompleter.complete(id);
      return writingToQueueCompleter.future;
    }

    final respCompleter = Completer<dynamic>();
    if (socket?.connected != true || isConnected == null || !isConnected!) {
      if (!isFromQueue && allowedForQueue.contains('$channel/$type')) {
        final int queuedItemId = await saveActionForLater();
        respCompleter
            .complete({'status': 'queued', 'queuedItemId': queuedItemId});
      } else {
        respCompleter.completeError(
            'Could not connect to server, please check your internet connection.');
      }
    } else {
      final crypted =
          await encodePayload({'type': type, 'payload': payload}, key, true);
      socket?.emitWithAck(channel, crypted, ack: (resp) async {
        payload = await decodePayload(
          resp['crypted'],
          resp['iv'],
          key,
          true,
        );
        debugPrint(payload.toString());
        if (payload['error'] != null) {
          respCompleter.completeError(payload['error']);
        } else if (payload['status'] == 'ok') {
          respCompleter.complete(payload['payload']);
        }
      });
    }
    return respCompleter.future;
  }

  static void emit(String channel, String type, dynamic payload) async {
    final crypted =
        await encodePayload({'type': type, 'payload': payload}, key, true);
    socket?.emit(channel, crypted);
  }

  static disconnectWS() {
    socket?.clearListeners();
    socket?.destroy();
    socket?.dispose();
    key = null;
    socket = null;
  }

  static resetConnection() {
    disconnectWS();
    connectWS();
  }

  static Future<void> _checkPendingKeyExchanges() async {
    try {
      // Get all chats and trigger key exchange checks
      final chatService = ChatService();
      final chats = obx.chats.getAll();

      // Check each one-to-one chat for pending key exchanges
      for (final chat in chats) {
        if (chat.isOneToOne) {
          await chatService.checkKeys(chat);
        }
      }

      debugPrint(
          'ChatSocket: Completed pending key exchange checks for ${chats.length} chats');
    } catch (e) {
      debugPrint('ChatSocket: Error checking pending key exchanges: $e');
    }
  }
}
