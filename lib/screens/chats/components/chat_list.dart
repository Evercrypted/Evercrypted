import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evercrypted/core/entities/chat-room/chat_room_model.dart';
import 'package:flutter/material.dart';
import '../../../core/entities/chat-room/chat_room_service.dart';
import '../../messages/message_screen.dart';
import 'chat_card.dart';

class ChatList extends StatelessWidget {
  ChatList({Key? key}) : super(key: key);

  final ChatRoomService _chatRoomService = ChatRoomService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _chatRoomService.getChatRooms(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          }
          List<ChatRoom> chatRooms =
              snapshot.data!.docs.map((DocumentSnapshot doc) {
            return ChatRoom.fromJson(
                doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              return ChatCard(
                chat: chatRooms[index],
                press: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagesScreen(
                      chatRoom: chatRooms[index],
                    ),
                  ),
                ),
              );
            },
          );
        });
  }
}

// class Body extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//           child: ListView.builder(
//             itemCount: chatsData.length,
//             itemBuilder: (context, index) => ChatCard(
//               chat: chatsData[index],
//               press: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => MessagesScreen(),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
