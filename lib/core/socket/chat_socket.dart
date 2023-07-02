import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/helpers.dart';

import 'package:evercrypted/core/offline/action_queue/action_queue.dart';
import 'package:evercrypted/core/services/socket_events_service.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:jwk/jwk.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';
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

  static const channelsToListen = [
    SocketChannelTypes.error,
    SocketChannelTypes.contactRequest,
    SocketChannelTypes.contact,
    SocketChannelTypes.settings,
  ];

  final SocketEventsService socketEventsService = SocketEventsService();

  static final ChatSocket instance = ChatSocket._();

  Future<bool> setKey(algo, publicKey) async {
    final respCompleter = Completer<bool>();
    final sharedSecretKey = await algo.sharedSecretKey(
      keyPair: keyPair!,
      remotePublicKey: Jwk.fromJson(publicKey).toPublicKey()!,
    );
    final keyBytes = await sharedSecretKey.extract();

    key = hex.encode(keyBytes.bytes);
    respCompleter.complete(true);
    return respCompleter.future;
  }

  getGeneralInfoAndExchangeKey(riverPodRef) async {
    final algo = X25519();

    // We need the private key pair of Alice.
    keyPair = await algo.newKeyPair();
    final SimplePublicKey localPublicKey = await keyPair!.extractPublicKey();
    print('connected');
    socket?.emitWithAck('general', {
      'type': 'getInitialData',
      'publicKey': Jwk.fromPublicKey(localPublicKey).toJson()
    }, ack: (dynamic resp) async {
      print(resp);
      await setKey(algo, resp['publicKey']);
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

  connectWS(String? token, WidgetRef riverPodRef) async {
    userToken = token;

    if (socket != null) {
      socket?.dispose();
      socket = null;
    }

    dynamic options =
        OptionBuilder().setTransports(['websocket']) // for Flutter or Dart VM
            .setExtraHeaders({
      'authorization': 'Bearer ${token ?? userToken}',
    });

    String? otpToken = await settingsService.getOtpToken();

    if (otpToken != null) {
      options = options.setExtraHeaders({'otpToken': otpToken});
    }

    socket = io.io('http://localhost:4000', options.build());

    if (socket?.connected != true) {
      socket?.connect();
    }

    socket?.onConnect((_) async {
      await getGeneralInfoAndExchangeKey(riverPodRef);
    });

    socket?.onReconnect((data) async {
      socket?.clearListeners();
      await getGeneralInfoAndExchangeKey(riverPodRef);
      setListeners(riverPodRef);
    });

    socket?.onDisconnect((_) {
      print('disconnect');
      socket?.clearListeners();
      socket?.destroy();
      socket?.dispose();
      key = null;
      socket = null;
    });

    socket?.onConnectError((data) {
      print('connect error');
      socket?.clearListeners();
      socket?.destroy();
      socket?.dispose();
      key = null;
      socket = null;
    });

    setListeners(riverPodRef);
  }

  setListeners(ref) {
    for (var channel in channelsToListen) {
      socket?.on(channel, (dynamic data) {
        final decrypted = decodePayload(
          data,
          key,
        );
        print(
          'got emit to $channel - $data:${decrypted.toString()}',
        );
        socketEventsService.handleEvent(
            ref, channel, decrypted['type'], decrypted['payload']);
      });
    }
  }

  Future<dynamic> emitWAck(String channel, String type, dynamic payload) async {
    saveActionForLater() async {
      final action = ActionQueue(
          type: type,
          channel: channel,
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
    socket?.dispose();
    socket = null;
  }
}
