import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:rxdart/rxdart.dart';

class ChatState {
  ChatState._();

  static BehaviorSubject<List<Chat>> subject = BehaviorSubject<List<Chat>>();

  static List<Chat> chats = [];

  static void setChats(List<Chat> chats) {
    ChatState.chats = chats;
    subject.add(chats);
  }

  static void addChat(Chat chat) {
    ChatState.chats.add(chat);
    subject.add(ChatState.chats);
  }
}
