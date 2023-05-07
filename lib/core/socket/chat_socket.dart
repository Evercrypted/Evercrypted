import 'dart:async';
import 'dart:convert';

import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue.dart';
import 'package:evercrypted/core/services/socket_events_service.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';

import '../entities/contact-request/contact_request_model.dart';
import '../entities/profile/profile_riverpod.dart';
import '../offline/action_queue/allowed_for_queue.dart';

class ChatSocket {
  ChatSocket._();
  final wsUrl = Uri.parse('ws://localhost:1234');
  io.Socket? socket;
  String? userToken;

  static const channelsToListen = [
    SocketChannelTypes.contactRequest,
    SocketChannelTypes.contact
  ];

  final SocketEventsService socketEventsService = SocketEventsService();

  static final ChatSocket instance = ChatSocket._();

  connectWS(String? token, WidgetRef riverPodRef) {
    userToken = token;

    if (socket != null) {
      socket?.dispose();
      socket = null;
    }

    socket = io.io(
        'http://localhost:4000',
        OptionBuilder().setTransports(['websocket']) // for Flutter or Dart VM
            .setExtraHeaders(
                {'authorization': 'Bearer ${token ?? userToken}'}) // optional
            .build());

    if (socket?.connected != true) {
      socket?.connect();
    }

    socket?.onConnect((_) {
      print('connected');
      socket?.emitWithAck('general', {'type': 'getInitialData'},
          ack: (dynamic resp) {
        print(resp);
        riverPodRef.read(receivedRequestsProvider.notifier).setReceivedRequests(
                (resp['userReceivedContacts'] as List<dynamic>)
                    .map((receivedRequest) {
              return ContactRequest.fromJson(receivedRequest);
            }).toList());
        riverPodRef.read(sentRequestsProvider.notifier).setSentRequests(
                (resp['userSentContacts'] as List<dynamic>).map((sentRequest) {
              return ContactRequest.fromJson(sentRequest);
            }).toList());
        riverPodRef.read(profileProvider).setProfileWhenSignIn(resp['profile']);
      });
    });

    socket?.onReconnect((data) {
      socket?.clearListeners();
      setListeners(riverPodRef);
    });

    socket?.onDisconnect((_) {
      print('disconnect');
      socket?.clearListeners();
      socket?.dispose();
      socket?.destroy();
      socket = null;
    });

    setListeners(riverPodRef);
  }

  setListeners(ref) {
    for (var channel in channelsToListen) {
      socket?.on(channel, (dynamic data) {
        print(
          'got emit to $channel - $data:${data.toString()}',
        );
        socketEventsService.handleEvent(
            ref, channel, data['type'], data['payload']);
      });
    }
  }

  Future<dynamic> emitWAck(String channel, String type, dynamic payload) {
    saveActionForLater() async {
      final action = ActionQueue(
          type: type,
          channel: channel,
          payload: json.encode(payload),
          createdAtMSE: DateTime.now().millisecondsSinceEpoch);
      final Isar isar =
          Isar.getInstance() ?? await Isar.open([ActionQueueSchema]);
      await isar.writeTxn(() async {
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
      socket?.emitWithAck(channel, {'type': type, 'payload': payload},
          ack: (resp) {
        if (resp['error'] != null) {
          respCompleter.completeError(resp['error']);
        } else {
          respCompleter.complete(resp);
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
