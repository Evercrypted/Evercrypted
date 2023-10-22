import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:flutter/material.dart';

class ChatList extends StatelessWidget {
  ChatList({Key? key}) : super(key: key);

  final ChatService _chatRoomService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Container();
    // return StreamBuilder(
    //     stream: _chatRoomService.getChatRooms(),
    //     builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    //       if (snapshot.hasError) {
    //         return const Text('Something went wrong');
    //       }

    //       if (snapshot.connectionState == ConnectionState.waiting) {
    //         return const Text("Loading");
    //       }
    //       List<Chat> chatRooms = [];
    //       return ListView.builder(
    //         itemCount: chatRooms.length,
    //         itemBuilder: (context, index) {
    //           return ChatCard(
    //             chat: chatRooms[index],
    //             press: () => Navigator.push(
    //               context,
    //               MaterialPageRoute(
    //                 builder: (context) => MessagesScreen(
    //                   chatRoom: chatRooms[index],
    //                 ),
    //               ),
    //             ),
    //           );
    //         },
    //       );
    //     });
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
