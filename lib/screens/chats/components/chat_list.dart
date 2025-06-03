import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/services/hidden_chat_service.dart';
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
    final profile = ref.watch(profileProvider);
    final HiddenChatService hiddenChatService = HiddenChatService();

    // Get hidden chat UIDs
    final hiddenChatUids = hiddenChatService.getHiddenChatUids(profile);

    // Get chats that match the search password
    final chatsMatchingPassword = searchValue.isNotEmpty
        ? hiddenChatService.getChatsMatchingPassword(searchValue, profile)
        : <String>{};

    if (searchValue.isNotEmpty) {
      return ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final isHidden = hiddenChatUids.contains(chat.uid);
          final matchesPassword = chatsMatchingPassword.contains(chat.uid);

          // Show chat if it matches password OR if it's not hidden and matches name
          if (matchesPassword ||
              (!isHidden &&
                  (chat.name ??
                          chatParticipantNames(chat: chat, widgetRef: ref)
                              .join(' , '))
                      .toLowerCase()
                      .contains(searchValue.toLowerCase()))) {
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
      // When not searching, filter out hidden chats
      return ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          // Don't show hidden chats
          if (hiddenChatUids.contains(chat.uid)) {
            return const SizedBox.shrink();
          }

          return ChatCard(
            chat: chat,
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
