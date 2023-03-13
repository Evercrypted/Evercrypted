import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/entities/chat-room/chat_room_model.dart';
import '../../core/entities/message/message_isar.dart';
import '../../ui_constants.dart';
import '../calling/audio_calling_screen.dart';
import '../calling/video_calling_screen.dart';
import 'components/body.dart';

class MessagesScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  const MessagesScreen({Key? key, required this.chatRoom}) : super(key: key);
  static const routeName = '/add-new-contact';

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _messageService = MessageService();

  @override
  void initState() {
    super.initState();
    getlastMessageCreatedAtMSE().then((value) {
      _messageService.startListeningAndWritingToDB(
          widget.chatRoom.fbUid!, value);
    });
  }

  Future<int?> getlastMessageCreatedAtMSE() async {
    final isar = await Isar.open([MessageSchema]);
    final lastMessageCreatedAtMSE = isar.messages
        .where()
        .chatIdEqualTo(widget.chatRoom.fbUid)
        .sortByCreatedAtMSE()
        .findFirstSync()
        ?.createdAtMSE;
    return lastMessageCreatedAtMSE;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _messageService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Body(),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          BackButton(),
          CircleAvatar(
            backgroundImage: AssetImage("assets/images/user_2.png"),
          ),
          SizedBox(width: defaultPadding * 0.75),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kristin Watson",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "Active 3m ago",
                style: TextStyle(fontSize: 12),
              )
            ],
          )
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.local_phone),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioCallingScreen(),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.videocam),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallingScreen(),
            ),
          ),
        ),
        SizedBox(width: defaultPadding / 2),
      ],
    );
  }
}
