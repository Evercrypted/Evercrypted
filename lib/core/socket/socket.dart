import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart';
import 'package:evercrypted/core/auth.dart';

import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_service.dart';
import 'package:evercrypted/core/services/socket_events_service.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/main.dart';
import 'package:jwk/jwk.dart';
import 'package:rxdart/subjects.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
import '../cryptography/combine_keys.dart';
import '../cryptography/payload.dart';
import '../offline/action_queue/allowed_for_queue.dart';
import '../services/settings_service.dart';

List<int> getNewNonce(byteLength, random) {
  final bytes = Uint8List(byteLength);
  fillBytesWithSecureRandom(
    bytes,
    random: random, // If null, the method will use Random.secure
  );
  return bytes;
}

class ChatSocket {
  ChatSocket._();
  static io.Socket? socket;
  static SimpleKeyPair? keyPair;
  static String? key;
  static final SettingsService settingsService = SettingsService();
  static final ActionQueueService actionQueueService = ActionQueueService();
  static final SocketEventsService socketEventsService = SocketEventsService();

  static bool? isConnected;

  static BehaviorSubject<bool> isConnectedSubject = BehaviorSubject<bool>();
  static BehaviorSubject<bool> resetConnectionSubject = BehaviorSubject<bool>();

  static num tries = 0;

  static const channelsToListen = [
    SocketChannelTypes.chat,
    SocketChannelTypes.error,
    SocketChannelTypes.contactRequest,
    SocketChannelTypes.contact,
    SocketChannelTypes.settings,
    SocketChannelTypes.message,
    SocketChannelTypes.auth,
  ];

  static getGeneralInfoAndExchangeKey() async {
    final keyCompleter = Completer<bool>();
    final algo = X25519();

    // We need the private key pair of Alice.
    keyPair = await algo.newKeyPair();
    final SimplePublicKey localPublicKey = await keyPair!.extractPublicKey();
    socket?.emitWithAck('general', {
      'type': 'getInitialData',
      'publicKey': Jwk.fromPublicKey(localPublicKey).toJson()
    }, ack: (dynamic resp) async {
      key = await combineKeys(algo, keyPair, resp['publicKey']);
      keyCompleter.complete(true);
      if (key != null) {
        final payload = await decodePayload(
          resp['crypted'],
          resp['iv'],
          resp['mac'],
          key,
        );
        socketEventsService.handleGeneralEvent('getInitialData', payload);
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

    final token = await Auth.getToken;

    var headers = {
      'authorization': 'Bearer $token',
    };

    final otpToken = await Auth.getOtpToken;

    if (otpToken != null) {
      headers['otpToken'] = otpToken;
    }

    options = options.setExtraHeaders(headers);

    io.cache.clear();
    socket = io.io('http://10.0.2.2:4000', options.build());
    // socket = io.io('http://localhost:4000', options.build());
    // socket = io.io('http://49.13.136.216:8080', options.build());

    if (socket?.connected != true) {
      socket?.connect();
    }

    socket?.onConnect((_) async {
      print('connected');
      socket?.clearListeners();
      await getGeneralInfoAndExchangeKey();
      actionQueueService.processQueue();
      setListeners();
      isConnected = true;
      isConnectedSubject.add(isConnected!);
    });

    socket?.onReconnect((data) async {
      socket?.clearListeners();
      await getGeneralInfoAndExchangeKey();
      actionQueueService.processQueue();
      setListeners();
      isConnected = true;
      isConnectedSubject.add(isConnected!);
    });

    socket?.on('disconnect', (data) {
      print('disconnected');
      isConnected = false;
      isConnectedSubject.add(isConnected!);
      disconnectWS();
    });

    socket?.onError((data) {
      final message = data is SocketException ? data.message : data['message'];
      if (data != null && message == 'Connection refused') {
        isConnected = false;
        isConnected = false;
        isConnectedSubject.add(isConnected!);
      }
    });

    socket?.onAny((event, data) {
      print('event $event');
      print('data $data');
      if (event == 'connected') {
        Auth.setToken(
          newToken: data['new_token'],
          skipNotify: true,
        );
      } else if (event == 'error') {
        socketEventsService.handleErrorEvent(data['type'], data['payload']);
      }
    });

    socket?.onDisconnect((_) {
      isConnected = false;
      isConnectedSubject.add(isConnected!);
      disconnectWS();
    });

    socket?.onConnectError((data) {
      isConnected = false;
      isConnectedSubject.add(isConnected!);
      disconnectWS();
    });

    setListeners();
  }

  static setListeners() {
    for (var channel in channelsToListen) {
      socket?.on(channel, (dynamic data) async {
        print('raw data: $data');
        dynamic payload;
        if (key != null) {
          payload = await decodePayload(
            data['crypted'],
            data['iv'],
            data['mac'],
            key,
          );
        } else {
          payload = data;
        }
        print(
          'got emit to $channel - ${payload.toString()}',
        );
        socketEventsService.handleEvent(
            channel, payload['type'], payload['payload']);
      });
    }
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
          await encodePayload({'type': type, 'payload': payload}, key);
      socket?.emitWithAck(channel, crypted, ack: (resp) async {
        payload = await decodePayload(
          resp['crypted'],
          resp['iv'],
          resp['mac'],
          key,
        );
        print(payload);
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
        await encodePayload({'type': type, 'payload': payload}, key);
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
}
