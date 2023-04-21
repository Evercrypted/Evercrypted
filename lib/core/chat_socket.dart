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
    socket = io.io(
        'http://localhost:4000',
        OptionBuilder().setTransports(['websocket']) // for Flutter or Dart VM
            .setExtraHeaders(
                {'authorization': 'Bearer ${token ?? userToken}'}) // optional
            .build());
    socket?.onConnect((_) {
      print('connected');
      socket?.emitWithAck('general', {'type': 'getInitialData'}, ack: (resp) {
        print(resp);
      });
    });

    socket?.on('msg', (data) => print(data));

    socket?.onDisconnect((_) {
      print('disconnect');
      socket?.dispose();
      socket = null;
    });
  }

  disconnectWS() {
    socket?.dispose();
    socket = null;
  }
}
