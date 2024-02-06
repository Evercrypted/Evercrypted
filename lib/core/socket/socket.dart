import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart';

import 'package:evercrypted/core/offline/action_queue/action_queue.dart';
import 'package:evercrypted/core/services/app_state_riverpod.dart';
import 'package:evercrypted/core/services/socket_events_service.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:jwk/jwk.dart';
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
  final wsUrl = Uri.parse('ws://localhost:1234');
  io.Socket? socket;
  String? userToken;
  SimpleKeyPair? keyPair;
  String? key;
  SettingsService settingsService = SettingsService();

  num tries = 0;

  static const channelsToListen = [
    SocketChannelTypes.chat,
    SocketChannelTypes.error,
    SocketChannelTypes.contactRequest,
    SocketChannelTypes.contact,
    SocketChannelTypes.settings,
    SocketChannelTypes.message
  ];

  final SocketEventsService socketEventsService = SocketEventsService();

  static final ChatSocket instance = ChatSocket._();

  getGeneralInfoAndExchangeKey(riverPodRef) async {
    final algo = X25519();

    // We need the private key pair of Alice.
    keyPair = await algo.newKeyPair();
    final SimplePublicKey localPublicKey = await keyPair!.extractPublicKey();
    socket?.emitWithAck('general', {
      'type': 'getInitialData',
      'publicKey': Jwk.fromPublicKey(localPublicKey).toJson()
    }, ack: (dynamic resp) async {
      key = await combineKeys(algo, keyPair, resp['publicKey']);
      if (key != null) {
        final payload = await decodePayload(
          resp,
          key,
        );
        print(payload);
        socketEventsService.handleGeneralEvent(
            riverPodRef, 'getInitialData', payload);
      }
    });
  }

  connectWS(String? token, WidgetRef ref) async {
    tries = tries + 1;
    userToken = token;

    if (socket != null) {
      socket?.destroy();
      socket?.dispose();
      socket = null;
    }

    dynamic options = OptionBuilder().setTransports(['websocket']);

    var headers = {
      'authorization': 'Bearer ${token ?? userToken}',
    };

    String? otpToken = await settingsService.getOtpToken();
    if (otpToken != null) {
      headers['otpToken'] = otpToken;
    }

    options = options.setExtraHeaders(headers);

    io.cache.clear();
    socket = io.io('http://localhost:4000', options.build());

    if (socket?.connected != true) {
      socket?.connect();
    }

    socket?.onConnect((_) async {
      ref.read(appStateProvider.notifier).setIsConnected(true);
    });

    socket?.onReconnect((data) async {
      socket?.clearListeners();
      ref.read(appStateProvider.notifier).setIsConnected(true);
      await getGeneralInfoAndExchangeKey(ref);
      setListeners(ref);
    });

    socket?.on('connected', (data) async {
      ref.read(appStateProvider.notifier).setIsConnected(true);
      await getGeneralInfoAndExchangeKey(ref);
    });

    socket?.onDisconnect((_) {
      ref.read(appStateProvider.notifier).setIsConnected(false);
      socket?.clearListeners();
      socket?.dispose();
      socket?.destroy();
      key = null;
      socket = null;
    });

    socket?.onConnectError((data) {
      ref.read(appStateProvider.notifier).setIsConnected(false);
      socket?.clearListeners();
      socket?.dispose();
      socket?.destroy();
      key = null;
      socket = null;
    });

    setListeners(ref);
  }

  setListeners(ref) {
    for (var channel in channelsToListen) {
      socket?.on(channel, (dynamic data) async {
        print('raw data: $data');
        dynamic payload;
        if (key != null) {
          payload = await decodePayload(
            data,
            key,
          );
        } else {
          payload = data;
        }
        print(
          'got emit to $channel - ${payload.toString()}',
        );
        socketEventsService.handleEvent(
            ref, channel, payload['type'], payload['payload']);
      });
    }
  }

  Future<dynamic> emitWAck(String channel, String type, dynamic payload) async {
    saveActionForLater() async {
      final action = ActionQueue(
          channel: channel,
          type: type,
          payload: json.encode(payload),
          createdAtMSE: DateTime.now().millisecondsSinceEpoch);
      final isar = Isar.getInstance();
      await isar?.writeTxn(() async {
        await isar.actionQueues.put(action);
      });
    }

    final respCompleter = Completer<dynamic>();
    if (instance.socket?.connected != true) {
      if (allowedForQueue.contains('$channel/$type')) {
        saveActionForLater();
        respCompleter.completeError('queued');
      } else {
        respCompleter.completeError(
            'Could not connect to server, please check your internet connection.');
      }
    } else {
      final crypted =
          await encodePayload({'type': type, 'payload': payload}, key);
      socket?.emitWithAck(channel, crypted, ack: (resp) async {
        payload = await decodePayload(
          resp,
          key,
        );
        if (payload['error'] != null) {
          respCompleter.completeError(payload['error']);
        } else if (payload['status'] == 'ok') {
          respCompleter.complete(payload['payload']);
        }
      });
    }
    return respCompleter.future;
  }

  disconnectWS() {
    socket?.clearListeners();
    socket?.destroy();
    socket?.dispose();
    key = null;
    socket = null;
  }
}
