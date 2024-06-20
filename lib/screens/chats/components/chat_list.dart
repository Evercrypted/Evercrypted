import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatList extends ConsumerWidget {
  const ChatList({super.key, required this.searchValue});

  final String searchValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Chat> chats = ref.watch(chatsProvider);

    if (searchValue.isNotEmpty) {
      return ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          if ((chat.name ??
                  chatParticipantNames(chat: chat, widgetRef: ref).join(' , '))
              .toLowerCase()
              .contains(searchValue.toLowerCase())) {
            return ChatCard(
              chat: chat,
              press: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagesScreen(
                    chat: chat,
                  ),
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      );
    } else {
      return ListView.builder(
        // Show messages from bottom to top
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return ChatCard(
            chat: chats[index],
            press: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessagesScreen(
                  chat: chats[index],
                ),
              ),
            ),
          );
        },
      );
    }
  }
}
