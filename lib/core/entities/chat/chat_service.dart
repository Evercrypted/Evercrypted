import 'dart:async';

import 'package:collection/collection.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/message/message_isar.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/event_types/chat_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'chat_model.dart';

class ChatService {
  ProfileService profileService = ProfileService();
  MessageService messageService = MessageService();

  Future<void> addChat(Chat chat) async {
    final isar = Isar.getInstance();
    return isar?.writeTxn(() async {
      await isar.chats.put(chat);
    });
  }

  Future<void> syncChats(List<Chat> chats) async {
    Completer<void> completer = Completer();

    final isar = Isar.getInstance();

    final List<Chat> chatsInDb = await isar!.chats.where().findAll();

    final List<Chat> chatsToPut = chats
        .where((element) =>
            chatsInDb.where((dbEl) => dbEl.uid == element.uid).isEmpty)
        .toList();

    final List<String> chatsToDelete = chatsInDb
        .where((element) => chats.where((el) => el.uid == element.uid).isEmpty)
        .map((e) => e.uid)
        .toList();

    final List<Chat> chatsToUpdate = chatsInDb.map((el) {
      final Chat? chat = chats.firstWhereOrNull((chat) => chat.uid == el.uid);
      if (chat != null) {
        chat.id = el.id;
        return chat;
      } else {
        return el;
      }
    }).toList();

    await isar.writeTxn(() async {
      await isar.chats.putAll([...chatsToUpdate, ...chatsToPut]);
      if (chatsToDelete.isNotEmpty) {
        for (var chat in chatsToDelete) {
          // delete all messages in chat
          final List<Message> msgsToDelete =
              await isar.messages.filter().chatUidEqualTo(chat).findAll();
          await isar.messages.deleteAll(msgsToDelete.map((e) => e.id).toList());
        }
        await isar.chats.deleteAllByUid(chatsToDelete);
      }
      completer.complete();
    });
    return completer.future;
  }

  Future<Chat> createNewChat(NewOneToOneChatDTO newChatDTO) async {
    Completer<Chat> complete = Completer();
    ChatSocket.emitWAck(SocketChannelTypes.chat, ChatEventTypes.createChat,
            newChatDTO.toJson())
        .then((resp) {
      final Chat returnedChat = Chat.fromJson(resp['chat']);
      addChat(returnedChat).then((value) => complete.complete(returnedChat));
    });
    return complete.future;
  }

  Future<Chat> createNewGroupChat(NewGroupChatDTO newGroupChatDTO) async {
    final Profile? profile = profileService.getProfile();
    newGroupChatDTO.participants.add(Participant(
        uid: profile!.uid,
        email: profile.email,
        name: profile.name,
        avatar: profile.avatar,
        isCreator: true,
        isAdmin: true));
    Completer<Chat> complete = Completer();
    ChatSocket.emitWAck(SocketChannelTypes.chat, ChatEventTypes.createGroupChat,
            newGroupChatDTO.toJson())
        .then((resp) {
      final Chat returnedChat = Chat.fromJson(resp['chat']);
      addChat(returnedChat).then((value) => complete.complete(returnedChat));
    });
    return complete.future;
  }

  openOneToOneChat(BuildContext context, WidgetRef ref, Contact contact) {
    List<Chat> chats = ref.read(chatsProvider);
    Chat? foundChat = chats
        .where((element) => (element.isOneToOne &&
            element.participants
                .any((element) => element.uid == contact.contactPersonUid)))
        .firstOrNull;
    if (foundChat != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesScreen(
            chat: foundChat,
          ),
        ),
        (route) => route.isFirst,
      );
    } else {
      NewOneToOneChatDTO newChat =
          NewOneToOneChatDTO(contact: contact.contactPersonUid!);
      createNewChat(newChat).then((Chat returnedChat) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(chat: returnedChat),
          ),
          (route) => route.isFirst,
        );
      });
    }
  }

  addParticipantsToChat(
      {required Chat chat, required List<Participant> participants}) {
    Completer<bool> completer = Completer();
    ChatSocket.emitWAck(
        SocketChannelTypes.chat, ChatEventTypes.addParticipants, {
      'chatUid': chat.uid,
      'contactUids': participants.map((p) => p.uid).toList()
    }).then((resp) {
      Chat updatedChat = chat;
      updatedChat.participants = [...chat.participants, ...participants];
      final isar = Isar.getInstance();
      isar?.writeTxn(() {
        return isar.chats.put(updatedChat);
      });
      completer.complete(true);
    }).catchError((error) {
      completer.completeError(false);
    });
    return completer.future;
  }

  removeParticipantFromChat(
      {required Chat chat, required Participant participant}) {
    Completer<bool> completer = Completer();
    ChatSocket.emitWAck(
        SocketChannelTypes.chat,
        ChatEventTypes.removeParticipant,
        {'chatUid': chat.uid, 'participantUid': participant.uid}).then((resp) {
      Chat updatedChat = chat;
      updatedChat.participants = updatedChat.participants
          .where((element) => element.uid != participant.uid)
          .toList();
      final isar = Isar.getInstance();
      isar?.writeTxn(() {
        return isar.chats.put(updatedChat);
      });
      completer.complete(true);
    }).catchError((error) {
      print(error);
      completer.completeError(false);
    });
  }

  leaveChat({required String chatUid}) {
    ChatSocket.emitWAck(SocketChannelTypes.chat, ChatEventTypes.leaveChat, {
      'chatUid': chatUid,
    }).then((resp) {
      deleteChat(chatUid: chatUid, skipNotify: true);
    });
  }

  updateChatFromResp(Chat chat) async {
    final isar = Isar.getInstance();
    final Chat? chatInDb =
        isar?.chats.where().uidEqualTo(chat.uid).findFirstSync();
    if (chatInDb != null) {
      chat.id = chatInDb.id;
      print(chat.toJson());
      return isar?.writeTxn(() {
        return isar.chats.put(chat);
      });
    }
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
        final messages =
            await isar.messages.where().chatUidEqualTo(chatUid).findAll();
        await isar.messages.deleteAll(messages.map((e) => e.id).toList());
        isar.chats.deleteByUid(chatUid);
      });
    }
  }

  updateChatLastSeen({String? chatUid}) {
    ChatSocket.emitWAck(SocketChannelTypes.chat,
        ChatEventTypes.updateChatLastSeen, chatUid ?? 'all');
  }
}
