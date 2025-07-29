import 'dart:async';

import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_state.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/services/hidden_chat_service.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatList extends ConsumerStatefulWidget {
  const ChatList({super.key, required this.searchValue});

  final String searchValue;
  @override
  ChatListState createState() => ChatListState();
}

class ChatListState extends ConsumerState<ChatList> {
  StreamSubscription<List<Chat>>? chatsSubscription;
  List<Chat> chats = ChatState.chats;
  final HiddenChatService hiddenChatService = HiddenChatService();

  @override
  void initState() {
    super.initState();
    chatsSubscription = ChatState.subject.listen((newChats) {
      setState(() {
        chats = newChats;
      });
    });
  }

  @override
  void dispose() {
    chatsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    // Get hidden chat UIDs
    final hiddenChatUids = hiddenChatService.getHiddenChatUids(profile);

    // Get chats that match the search password
    final chatsMatchingPassword = widget.searchValue.isNotEmpty
        ? hiddenChatService.getChatsMatchingPassword(
            widget.searchValue, profile)
        : <String>{};

    if (widget.searchValue.isNotEmpty) {
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
                      .contains(widget.searchValue.toLowerCase()))) {
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
      return ListView(
        children: [
          for (var chat in chats)
            if (hiddenChatUids.contains(chat.uid))
              const SizedBox.shrink()
            else
              ChatCard(
                key: Key(chat.uid),
                chat: chat,
                press: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagesScreen(
                      chat: chat,
                    ),
                  ),
                ),
              ),
        ],
      );
    }
  }
}
