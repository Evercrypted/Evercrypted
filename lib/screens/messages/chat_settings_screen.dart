import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
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
  late Participant user;

  @override
  void initState() {
    user = widget.chat.participants
        .firstWhere((p) => p.email == Auth.getUser!.email);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Chat chat =
        ref.watch(chatsProvider).firstWhere((c) => c.uid == widget.chat.uid);
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
              ),
            if ((user.isCreator || user.isAdmin) && !chat.isOneToOne) ...[
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Participant'),
                ),
              )
            ],
            if (user.isCreator || chat.participants.length == 2) ...[
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {},
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
            ]
          ],
        )));
  }
}
