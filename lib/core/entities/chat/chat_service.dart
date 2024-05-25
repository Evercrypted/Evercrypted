import 'dart:async';

import 'package:collection/collection.dart';
import 'package:evercrypted/core/entities/message/message_isar.dart';
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

    final List<String> chatsToDelete = chatsInDb
        .where((element) => chats.where((el) => el.uid == element.uid).isEmpty)
        .map((e) => e.uid)
        .toList();

    await isar.writeTxn(() async {
      await isar.chats.putAll(contactRequestsToPut);
      await isar.chats.deleteAllByUid(chatsToDelete);
      final List<Message> msgsToDelete = await isar.messages
          .filter()
          .anyOf(chatsToDelete, (q, uid) => q.chatUidEqualTo(uid))
          .findAll();
      await isar.messages.deleteAll(msgsToDelete.map((el) => el.id).toList());
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

  Future<bool> findContactChatAndDelete(
      {required String contactUid, bool skipNotify = false}) async {
    final isar = Isar.getInstance();
    final chats = isar!.chats.where().findAllSync();
    final chat = chats.firstWhereOrNull((chat) {
      return chat.participants.length == 2 &&
          chat.participants.any((participant) => participant.uid == contactUid);
    });
    if (chat != null) {
      deleteChat(chatUid: chat.uid, skipNotify: skipNotify);
      return true;
    } else {
      return false;
    }
  }

  deleteChat({required String chatUid, bool? skipNotify = false}) async {
    final isar = Isar.getInstance();
    if (skipNotify == false) {
      ChatSocket.emitWAck(
          SocketChannelTypes.chat, ChatEventTypes.deleteChat, chatUid);
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
    } else {
      isar?.writeTxn(() async {
        isar.chats.deleteByUid(chatUid);
      });
    }
  }
}
