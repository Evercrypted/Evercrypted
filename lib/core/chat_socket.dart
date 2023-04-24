import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';

class ChatSocket {
  ChatSocket._();
  final wsUrl = Uri.parse('ws://localhost:1234');
  io.Socket? socket;
  String? userToken;

  static final ChatSocket instance = ChatSocket._();

  connectWS(String? token) {
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
      socket?.emitWithAck('general', {'type': 'getInitialData'}, ack: (resp) {
        print(resp);
      });
    });

    socket?.onReconnect((data) {
      print('reconnect');
    });

    socket?.onDisconnect((_) {
      print('disconnect');
      socket?.dispose();
      socket?.destroy();
      socket = null;
    });

    setListeners();
  }

  setListeners() {
    socket?.on('msg', (data) => print(data));
  }

  disconnectWS() {
    socket?.dispose();
    socket = null;
  }
}
