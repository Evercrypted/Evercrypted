import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/models/ChatMessage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../core/entities/chat-room/chat_room_model.dart';
import '../../core/entities/message/message_isar.dart';
import '../../ui_constants.dart';
import '../calling/audio_calling_screen.dart';
import '../calling/video_calling_screen.dart';
import 'components/body.dart';
import 'components/chat_input_field.dart';
import 'components/message.dart';

class MessagesScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  const MessagesScreen({Key? key, required this.chatRoom}) : super(key: key);
  static const routeName = '/add-new-contact';

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _messageService = MessageService();
  Isar? isar;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  static const _pageSize = 20;

  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    getlastMessageCreatedAtMSE().then((value) {
      _messageService.startListeningAndWritingToDB(widget.chatRoom, value);
    });
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _messageService.stopListening();
    isar?.close();
    super.dispose();
  }

  Future<int?> getlastMessageCreatedAtMSE() async {
    isar = Isar.getInstance() ?? await Isar.open([MessageSchema]);
    final lastMessageCreatedAtMSE = isar?.messages
        .where()
        .chatIdEqualTo(widget.chatRoom.fbUid)
        .sortByCreatedAtMSE()
        .findFirstSync()
        ?.createdAtMSE;
    return lastMessageCreatedAtMSE;
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems =
          await _messageService.getMessagesFromDB(pageKey, _pageSize);
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  onNewMessage(newMessage) {
    _pagingController.value = PagingState(
      itemList: [newMessage, ...(_pagingController.itemList ?? [])],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: PagedListView<int, Message>(
                  reverse: true,
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<Message>(
                      itemBuilder: (context, item, index) {
                    final chatMessage = ChatMessage(
                      text: item.text!,
                      messageType: ChatMessageType.text,
                      isSender: item.authorId == userId,
                      messageStatus: MessageStatus.viewed,
                    );
                    return MessageWidget(message: chatMessage);
                  }),
                ),
              ),
            ),
            ChatInputField(
              chatId: widget.chatRoom.fbUid!,
            ),
          ],
        ));
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
