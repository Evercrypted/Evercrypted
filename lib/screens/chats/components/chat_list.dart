import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatList extends ConsumerStatefulWidget {
  const ChatList({super.key});

  @override
  ChatListState createState() => ChatListState();
}

class ChatListState extends ConsumerState<ChatList> {
  @override
  Widget build(BuildContext context) {
    final List<Chat> chats = ref.watch(chatsProvider);

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
