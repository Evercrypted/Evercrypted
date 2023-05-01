import 'dart:async';

import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/core/services/socket_events_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';

import 'entities/contact-request/contact_request_model.dart';

class ChatSocket {
  ChatSocket._();
  final wsUrl = Uri.parse('ws://localhost:1234');
  io.Socket? socket;
  String? userToken;

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
      });
    });

    socket?.onReconnect((data) {
      print('reconnect');
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
    socket?.on('contactRequest', (dynamic data) {
      print(
        'got emit $data:${data.toString()}',
      );
      socketEventsService.handleEvent(
          ref, 'contactRequest', data['type'], data['payload']);
    });
  }

  Future<dynamic> emitWAck(String channel, String type, dynamic payload) {
    final respCompleter = Completer<dynamic>();
    socket?.emitWithAck(channel, {'type': type, 'payload': payload},
        ack: (resp) {
      if (resp['error'] != null) {
        respCompleter.completeError(resp['error']);
      } else {
        respCompleter.complete(resp);
      }
    });
    return respCompleter.future;
  }

  disconnectWS() {
    socket?.dispose();
    socket = null;
  }
}
