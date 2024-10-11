import 'dart:async';

import 'package:collection/collection.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/base_key.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/event_types/chat_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_model.dart';

class ChatService {
  ProfileService profileService = ProfileService();
  MessageService messageService = MessageService();

  Future<Chat> addChat(Chat chat) async {
    final String appKey = await Auth.getAppKey;

    _syncKeysIfSyncRequired(chat);

    chat.participants.addAll(chat.participantsList.map((p) {
      return p.copyWith(
          email: fernetEncrypt(p.email, appKey),
          name: fernetEncrypt(p.name, appKey));
    }));

    objectbox.chats.put(chat);
    return chat;
  }

  Future<void> syncChats(List<Chat> chats) async {
    Completer<void> completer = Completer();

    final List<Chat> chatsInDb = objectbox.chats.getAll();

    final Iterable<Chat> chatsToPut = chats.where((element) =>
        chatsInDb.where((dbEl) => dbEl.uid == element.uid).isEmpty);

    final Iterable<Chat> chatsToDelete = chatsInDb
        .where((element) => chats.where((el) => el.uid == element.uid).isEmpty);

    final Iterable<Chat> chatsToUpdate = chatsInDb.map((el) {
      final Chat? chat = chats.firstWhereOrNull((chat) => chat.uid == el.uid);
      if (chat != null) {
        chat.id = el.id;
        return chat;
      } else {
        return el;
      }
    });

    final String appKey = await Auth.getAppKey;

    List<Chat> allChats = [...chatsToUpdate, ...chatsToPut];
    for (var chat in allChats) {
      final List<int> particiapantIds =
          chat.participants.map((p) => p.id).toList();
      objectbox.participants.removeMany(particiapantIds);
      chat.participants.addAll(chat.participantsList.map((Participant p) {
        return p.copyWith(
            email: fernetEncrypt(p.email, appKey),
            name: fernetEncrypt(p.name, appKey));
      }));
      objectbox.messages.putMany(chat.messages);
    }

    _doSyncForAllChats(allChats);

    objectbox.chats.putMany(allChats);

    if (chatsToDelete.isNotEmpty) {
      for (var chat in chatsToDelete) {
        final List<int> messageIds = chat.messages.map((m) => m.id).toList();
        objectbox.messages.removeMany(messageIds);
        objectbox.chats.remove(chat.id);
      }
    }

    completer.complete();
    return completer.future;
  }

  Future<Chat> createNewChat(NewOneToOneChatDTO newChatDTO) async {
    Completer<Chat> complete = Completer();
    final Base64KeyData keys = await BaseKey.generateKeys();

    newChatDTO.pubKey = keys.publicKey;

    ChatSocket.emitWAck(SocketChannelTypes.chat, ChatEventTypes.createChat,
            newChatDTO.toJson())
        .then((resp) async {
      Chat returnedChat = Chat.fromJson(resp['chat']);
      await BaseKey.setPrivate(returnedChat.uid, keys.keyPair);
      addChat(returnedChat).then((chat) {
        complete.complete(chat);
      });
    });
    return complete.future;
  }

  Future<Chat> updatePubKey(
      {required String chatUid, String? pubKey, bool? gotPubKey}) async {
    Completer<Chat> complete = Completer();
    ChatSocket.emitWAck(SocketChannelTypes.chat, ChatEventTypes.updatePubKey, {
      'chatUid': chatUid,
      'pubKey': pubKey,
      'gotPubKey': gotPubKey
    }).then((resp) async {
      await updateChatFromResp(Chat.fromJson(resp['chat']));
      complete.complete(Chat.fromJson(resp['chat']));
    });
    return complete.future;
  }

  Future<Chat> createNewGroupChat(NewGroupChatDTO newGroupChatDTO) async {
    Completer<Chat> complete = Completer();

    final String appKey = await Auth.getAppKey;

    final Profile? profile = profileService.getProfile();

    newGroupChatDTO.participants.add(Participant(
        uid: profile!.uid,
        email: fernetDecrypt(profile.email, appKey),
        name: fernetDecrypt(profile.name, appKey),
        avatarColor: profile.avatarColor,
        avatarIcon: profile.avatarIcon,
        avatarPic: profile.avatarPic,
        isCreator: true,
        isAdmin: true));

    ChatSocket.emitWAck(SocketChannelTypes.chat, ChatEventTypes.createGroupChat,
            newGroupChatDTO.toJson())
        .then((resp) {
      addChat(Chat.fromJson(resp['chat'])).then((chat) {
        return complete.complete(chat);
      });
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
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MessagesScreen(chat: returnedChat),
            ),
            (route) => route.isFirst,
          );
        }
      });
    }
  }

  addParticipantsToChat(
      {required Chat chat, required List<Participant> participants}) async {
    Completer<bool> completer = Completer();

    final String appKey = await Auth.getAppKey;

    ChatSocket.emitWAck(
        SocketChannelTypes.chat, ChatEventTypes.addParticipants, {
      'chatUid': chat.uid,
      'contactUids': participants.map((p) => p.uid).toList()
    }).then((resp) {
      final participantsToAdd = participants.map((p) {
        return p.copyWith(
            email: fernetEncrypt(p.email, appKey),
            name: fernetEncrypt(p.name, appKey));
      }).toList();
      final chatFromDb = objectbox.chats.get(chat.id);
      chatFromDb?.participants.addAll(participantsToAdd);
      objectbox.chats.put(chatFromDb!);
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
      if (chat.isOneToOne) {
        _syncKeysIfSyncRequired(chat);
      }
      final String appKey = await Auth.getAppKey;
      chat.participants = chat.participants.map((p) {
        return p.copyWith(
            email: fernetEncrypt(p.email, appKey),
            name: fernetEncrypt(p.name, appKey));
      }).toList();
      chat.id = chatInDb.id;
      return isar?.writeTxn(() {
        return isar.chats.put(chat);
      });
    }
  }

  _doSyncForAllChats(List<Chat> chats) async {
    for (var chat in chats) {
      if (chat.isOneToOne) {
        _syncKeysIfSyncRequired(chat);
      }
    }
  }

  _syncKeysIfSyncRequired(Chat chat) async {
    final AuthUser? user = Auth.getUser;
    if (user != null && chat.syncRequired == true) {
      final Participant? thisParticipant = chat.participants
          .firstWhereOrNull((element) => element.uid == user.uid);
      final Participant? otherParticipant = chat.participants
          .firstWhereOrNull((element) => element.uid != user.uid);
      if (otherParticipant != null && thisParticipant != null) {
        if (otherParticipant.pubKey != null) {
          if (thisParticipant.pubKey != null) {
            final private = await BaseKey.getPrivate(chat.uid);
            if (private != null) {
              BaseKey.combine(private, otherParticipant.pubKey!).then((key) {
                if (key != null) {
                  BaseKey.setBase(chat.uid, key);
                  updatePubKey(chatUid: chat.uid, gotPubKey: true);
                }
              });
            } else {
              //reset sync
            }
          } else {
            BaseKey.generateKeys().then((keys) {
              BaseKey.combine(keys.keyPair, otherParticipant.pubKey!)
                  .then((key) {
                if (key != null) {
                  BaseKey.setBase(chat.uid, key);
                  updatePubKey(
                      chatUid: chat.uid,
                      pubKey: keys.publicKey,
                      gotPubKey: true);
                }
              });
            });
          }
        } else {
          if (thisParticipant.pubKey == null) {
            BaseKey.generateKeys().then((keys) {
              BaseKey.setPrivate(chat.uid, keys.keyPair);
              updatePubKey(
                chatUid: chat.uid,
                pubKey: keys.publicKey,
              );
            });
          }
        }
      }
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
