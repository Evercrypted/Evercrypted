import 'package:collection/collection.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
import 'package:evercrypted/screens/contacts/contacts_screen.dart';
import 'package:evercrypted/screens/messages/components/participant_card.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatSettingsScreen extends ConsumerStatefulWidget {
  const ChatSettingsScreen(this.chat, {super.key});

  final Chat chat;

  @override
  ChatSettingsScreenState createState() => ChatSettingsScreenState();
}

class ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  ChatService chatService = ChatService();
  late Participant user;
  late Chat chat;

  @override
  void initState() {
    chat = widget.chat;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Chat>>(chatsProvider, (prev, next) {
      setState(() {
        late final Chat? chatOrNull;
        chatOrNull = next.firstWhereOrNull((c) => c.uid == widget.chat.uid);
        if (chatOrNull != null) {
          chat = chatOrNull;
        } else {
          Navigator.popUntil(context, (r) => r.isFirst);
        }
      });
    });

    user = chat.participants.firstWhere((p) => p.email == Auth.getUser!.email);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Chat Settings'),
        ),
        body: SingleChildScrollView(
            child: Column(
          children: [
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatarWithActiveIndicator(
                  image: chat.avatar?.pic,
                  radius: 50,
                  name: chat.name ??
                      chatParticipantNames(chat: chat, widgetRef: ref)
                          .join(', '),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5, top: 5),
                  child: InkWell(
                    onTap: () {},
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 17,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: primaryColor,
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    chat.name ??
                        chatParticipantNames(chat: chat, widgetRef: ref)
                            .join(', '),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Last Message ${timeago.format(chat.lastMessageTime!)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: lightGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            for (final participant in chat.participants
                .where((p) => p.email != Auth.getUser!.email))
              ParticipantCard(
                user: user,
                participant: participant,
                participantsLenght: chat.participants.length,
                remove: () => chatService.removeParticipantFromChat(
                    chat: chat, participant: participant),
              ),
            if ((user.isCreator || user.isAdmin) && !chat.isOneToOne) ...[
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactsScreen(
                          isParticipantSelect: true,
                          isAddNewParticipants: true,
                          participants: chat.participants
                              .where((p) => p.email != Auth.getUser!.email)
                              .toList(),
                        ),
                      ),
                    ).then((val) {
                      if (val != null && val.length > 0) {
                        chatService.addParticipantsToChat(
                            chat: chat, participants: val);
                      }
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Participant'),
                ),
              )
            ],
            if (user.isCreator || chat.isOneToOne) ...[
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    ModalRoute.of(context)!
                        .completed
                        .then((_) => chatService.deleteChat(chatUid: chat.uid));
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Delete Chat',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
            if (!user.isCreator && !chat.isOneToOne) ...[
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    ModalRoute.of(context)!
                        .completed
                        .then((_) => chatService.leaveChat(chatUid: chat.uid));
                  },
                  icon: const Icon(
                    Icons.exit_to_app,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Leave Chat',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ]
          ],
        )));
  }
}
