import 'dart:async';

import 'package:collection/collection.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/base_key.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
import 'package:evercrypted/core/cryptography/one_to_one_pubkey_comb.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/event_types/chat_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_model.dart';

class ChatService {
  ProfileService profileService = ProfileService();
  MessageService messageService = MessageService();

  Chat addChat(Chat chat) {
    _syncKeysIfSyncRequired(chat);

    final int id = obx.chats.put(chat);
    chat.id = id;
    return chat;
  }

  Future<void> syncChats(List<Chat> chats) async {
    Completer<void> completer = Completer();

    final List<Chat> chatsInDb = obx.chats.getAll();

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

    List<Chat> allChats = [...chatsToUpdate, ...chatsToPut];
    for (var chat in allChats) {
      obx.messages.putMany(chat.messages);
    }

    _doSyncForAllChats(allChats);

    obx.chats.putMany(allChats);

    if (chatsToDelete.isNotEmpty) {
      for (var chat in chatsToDelete) {
        final List<int> messageIds = chat.messages.map((m) => m.id).toList();
        obx.messages.removeMany(messageIds);
        obx.chats.remove(chat.id);
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
      final Chat returnedChat = Chat.fromJson(resp['chat']);
      await BaseKey.setPrivate(returnedChat.uid, keys.keyPair);
      final Chat chat = addChat(returnedChat);
      complete.complete(chat);
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
        avatar: profile.avatar,
        isCreator: true,
        isAdmin: true));

    ChatSocket.emitWAck(SocketChannelTypes.chat, ChatEventTypes.createGroupChat,
            newGroupChatDTO.toJson())
        .then((resp) {
      final Chat chat = addChat(Chat.fromJson(resp['chat']));
      return complete.complete(chat);
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

    ChatSocket.emitWAck(
        SocketChannelTypes.chat, ChatEventTypes.addParticipants, {
      'chatUid': chat.uid,
      'contactUids': participants.map((p) => p.uid).toList()
    }).then((resp) {
      final chatFromDb = obx.chats.get(chat.id);
      chatFromDb?.participants.addAll(participants);
      obx.chats.put(chatFromDb!);
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
      final chatFromDb = obx.chats.get(chat.id);
      if (chatFromDb == null) {
        completer.completeError(false);
      }
      chatFromDb!.participants.remove(participant);
      obx.chats.put(chatFromDb);
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
    final query = obx.chats.query(Chat_.uid.equals(chat.uid)).build();
    final Chat? chatInDb = query.findFirst();
    query.close();

    if (chatInDb != null) {
      if (chat.isOneToOne) {
        _syncKeysIfSyncRequired(chat);
      }
      chat.id = chatInDb.id;
      obx.chats.put(chat);
    }
  }

  _doSyncForAllChats(List<Chat> chats) async {
    for (var chat in chats) {
      if (chat.isOneToOne) {
        _syncKeysIfSyncRequired(chat);
      }
    }
  }

  _checkKeys(Chat chat) async {
    if (chat.participants.length > 2) {
      return;
    } else {
      final String? pubKeyComb = oneToOnePubkeyComb(chat.participants);
      if (pubKeyComb != null) {}
    }
  }

  _syncKeysIfSyncRequired(Chat chat) async {
    final AuthUser user = Auth.getUser!;
    if (chat.syncRequired == true) {
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
    final chats = obx.chats.getAll();
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
    delete() {
      final query = obx.chats.query(Chat_.uid.equals(chatUid)).build();
      final chatInDb = query.findFirst();
      query.close();
      if (chatInDb != null) {
        chatInDb.messages.clear();
        chatInDb.messages.applyToDb();
        obx.chats.remove(chatInDb.id);
      }
    }

    if (skipNotify == false) {
      return ChatSocket.emitWAck(
              SocketChannelTypes.chat, ChatEventTypes.deleteChat, chatUid)
          .then((resp) {
        delete();
      }).onError((error, stackTrace) {
        if (error == 'No such chat found') {
          delete();
        }
      });
    } else {
      delete();
    }
  }

  updateChatLastSeen({String? chatUid}) {
    ChatSocket.emitWAck(SocketChannelTypes.chat,
        ChatEventTypes.updateChatLastSeen, chatUid ?? 'all');
  }
}
