import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_model.dart';

class ChatsNotifier extends StateNotifier<List<Chat>> {
  // We initialize the list of todos to an empty list
  ChatsNotifier() : super([]);

  void setChats(List<Chat> chats) {
    state = [...chats];
  }

  void addChat(Chat chat) {
    state = [chat, ...state];
  }
}

final chatsProvider = StateNotifierProvider<ChatsNotifier, List<Chat>>((ref) {
  return ChatsNotifier();
});
