import 'dart:async';

import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/event_types/chat_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:isar/isar.dart';

import 'chat_model.dart';

class ChatService {
  Future<void> syncChats(List<Chat> chats) async {
    Completer<void> complete = Completer();

    final isar = Isar.getInstance();

    final List<Chat> chatsInDb = await isar!.chats.where().findAll();

    final List<Chat> contactRequestsToPut = chats
        .where((element) =>
            chatsInDb.where((dbEl) => dbEl.uid == element.uid).isEmpty)
        .toList();

    await isar.writeTxn(() async {
      await isar.chats.putAll(contactRequestsToPut);
      complete.complete();
    });
    return complete.future;
  }

  Future<Chat> createNewChat(NewChatDTO newChatDTO) async {
    Completer<Chat> complete = Completer();
    ChatSocket.emitWAck(SocketChannelTypes.chat, ChatEventTypes.createChat,
            newChatDTO.toJson())
        .then((resp) {
      final Chat returnedChat = Chat.fromJson(resp['chat']);
      syncChats([returnedChat])
          .then((value) => complete.complete(returnedChat));
    });
    return complete.future;
  }

  findContactChatAndDelete(String contactUid) async {
    // final isar = Isar.getInstance();
    // final chat = await isar!.chats
    //     .where()
    //     .filter()
    //     .contactUidsEqualTo([contactUid])
    //     .findFirst();
    // if (chat != null) {
    //   deleteChat(chat.uid);
    // }
  }

  deleteChat(String chatUid) async {
    final isar = Isar.getInstance();
    return ChatSocket.emitWAck(
            SocketChannelTypes.chat, ChatEventTypes.deleteChat, chatUid)
        .then((resp) {
      isar?.writeTxn(() async {
        isar.chats.deleteByUid(chatUid);
      });
    }).onError((error, stackTrace) {
      if (error == 'No such chat found') {
        isar?.writeTxn(() async {
          isar.chats.deleteByUid(chatUid);
        });
      }
    });
  }
}
