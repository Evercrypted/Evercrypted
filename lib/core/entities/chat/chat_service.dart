import 'dart:async';

import 'package:collection/collection.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/db_encryption.dart';
import 'package:evercrypted/core/cryptography/group_key_exchange.dart';
import 'package:evercrypted/core/entities/chat/chat_state.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/services/hidden_chat_service.dart';
import 'package:evercrypted/core/socket/event_types/chat_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_model.dart';

class ChatService {
  ProfileService profileService = ProfileService();
  MessageService messageService = MessageService();

  Chat addChat(Chat chat, {bool isNewlyCreated = false}) {
    checkKeys(chat);

    // Preserve existing ObjectBox ID to avoid unique constraint violation
    if (chat.id == 0) {
      final query = ObxInit.obx.chats.query(Chat_.uid.equals(chat.uid)).build();
      final existing = query.findFirst();
      query.close();
      if (existing != null) {
        chat.id = existing.id;
      }
    }

    final int id = ObxInit.obx.chats.put(chat);
    chat.id = id;

    // Auto-generate group key ONLY for newly created group chats where I'm the creator
    if (!chat.isOneToOne && isNewlyCreated) {
      final userId = Auth.user?.uid;
      final isCreator =
          chat.participants.any((p) => p.uid == userId && p.isCreator == true);

      if (isCreator) {
        GroupKeyExchange.createAndDistributeGroupKey(chat.uid);
      }
    }

    return chat;
  }

  Future<void> syncChats(List<Chat> chats) async {
    Completer<void> completer = Completer();

    final List<Chat> chatsInDb = ObxInit.obx.chats.getAll();

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
    if (allChats.isNotEmpty) {
      _doSyncForAllChats(allChats);

      ObxInit.obx.chats.putMany(allChats);
    }

    for (var chat in allChats) {
      final query = ObxInit.obx.chats.query(Chat_.uid.equals(chat.uid)).build();
      final dbChat = query.findFirst();
      query.close();
      if (dbChat != null) {
        // Only add messages that don't already exist to prevent uniqueId conflicts

        for (var newMessage in chat.messagesList) {
          // Process group key exchange messages in background (don't store in DB)
          if (newMessage.messageType == MessageTypes.requestForAGroupKey ||
              newMessage.messageType == MessageTypes.responseForAGroupKey) {
            await MessageProcessor.processMessage(newMessage);
            continue; // Don't store these protocol messages in DB
          }

          final existingMessage = dbChat.messages.firstWhereOrNull((msg) =>
              msg.uid == newMessage.uid || msg.uniqueId == newMessage.uniqueId);
          if (existingMessage == null) {
            dbChat.messages.add(newMessage);
          }
        }
        ObxInit.obx.chats.put(dbChat);
      }
    }

    if (chatsToDelete.isNotEmpty) {
      // Process chat deletions in parallel for better performance
      final List<Future<void>> deletionFutures =
          chatsToDelete.map((chat) async {
        try {
          // Clean up all message files for this chat in background (fire-and-forget)
          final filePaths =
              await messageService.buildFilePathsForMessages(chat.messages);
          if (filePaths.isNotEmpty) {
            messageService.deleteFiles(filePaths);
          }

          // Remove messages and chat from database immediately
          final List<int> messageIds = chat.messages.map((m) => m.id).toList();
          ObxInit.obx.messages.removeMany(messageIds);
          ObxInit.obx.chats.remove(chat.id);
        } catch (error) {
          // Continue with other chat deletions even if one fails
        }
      }).toList();

      // Wait for all chat deletions to complete
      await Future.wait(deletionFutures);
    }

    completer.complete();
    return completer.future;
  }

  Future<Chat> createNewChat(NewOneToOneChatDTO newChatDTO) async {
    Completer<Chat> complete = Completer();

    AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.createChat,
      payload: newChatDTO.toJson(),
    ).then((resp) async {
      final Chat returnedChat = Chat.fromJson(resp['chat']);
      // Generate and store random key (unified approach for all chat types)
      await GroupKeyExchange.createAndDistributeGroupKey(returnedChat.uid);
      final Chat chat = addChat(returnedChat, isNewlyCreated: true);
      complete.complete(chat);
    });
    return complete.future;
  }

  Future<Chat> updatePubKey({required String chatUid, String? pubKey}) async {
    Completer<Chat> complete = Completer();
    AppHttpClient.message(
        channel: SocketChannelTypes.chat,
        type: ChatEventTypes.updatePubKey,
        payload: {
          'chatUid': chatUid,
          'pubKey': pubKey,
        }).then((resp) async {
      final Chat chat = Chat.fromJson(resp['chat']);
      await updateChatFromResp(chat);
      complete.complete(chat);
    });
    return complete.future;
  }

  Future<Chat> createNewGroupChat(NewGroupChatDTO newGroupChatDTO) async {
    Completer<Chat> complete = Completer();

    final String appKey = await Auth.getAppKey;

    final Profile? profile = profileService.getProfile();

    newGroupChatDTO.participants.add(Participant(
        uid: profile!.uid,
        email: decryptForDb(profile.email, appKey),
        name: decryptForDb(profile.name, appKey),
        avatar: profile.avatar,
        isCreator: true,
        isAdmin: true));

    AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.createGroupChat,
      payload: newGroupChatDTO.toJson(),
    ).then((resp) {
      final Chat chat =
          addChat(Chat.fromJson(resp['chat']), isNewlyCreated: true);
      return complete.complete(chat);
    });
    return complete.future;
  }

  openOneToOneChat(BuildContext context, WidgetRef ref, Contact contact) {
    List<Chat> chats = ChatState.chats;

    // Get hidden chat UIDs to filter them out
    final profile = profileService.getProfile();
    final hiddenChatService = HiddenChatService();
    final hiddenChatUids = hiddenChatService.getHiddenChatUids(profile);

    // Find all one-to-one chats with this contact
    final chatsWithContact = chats
        .where((element) => (element.isOneToOne &&
            element.participants
                .any((element) => element.uid == contact.contactPersonUid)))
        .toList();

    // Only consider non-hidden chats
    Chat? foundChat = chatsWithContact
        .where((chat) => !hiddenChatUids.contains(chat.uid))
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
      // Capture navigator before async call to ensure navigation works
      final navigator = Navigator.of(context);

      // Create new chat if no non-hidden chat exists (server now allows multiple chats per contact)
      NewOneToOneChatDTO newChat =
          NewOneToOneChatDTO(contact: contact.contactPersonUid!);
      createNewChat(newChat).then((Chat returnedChat) {
        // Add to ChatState so it's immediately available for future lookups
        ChatState.addChat(returnedChat);
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MessagesScreen(chat: returnedChat),
          ),
          (route) => route.isFirst,
        );
      });
    }
  }

  addParticipantsToChat(
      {required Chat chat, required List<Participant> participants}) async {
    Completer<bool> completer = Completer();

    AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.addParticipants,
      payload: {
        'chatUid': chat.uid,
        'contactUids': participants.map((p) => p.uid).toList()
      },
    ).then((resp) {
      final chatFromDb = ObxInit.obx.chats.get(chat.id);
      chatFromDb?.participants.addAll(participants);
      ObxInit.obx.chats.put(chatFromDb!);
      completer.complete(true);
    }).catchError((error) {
      completer.completeError(false);
    });
    return completer.future;
  }

  removeParticipantFromChat(
      {required Chat chat, required Participant participant}) {
    Completer<bool> completer = Completer();
    AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.removeParticipant,
      payload: {'chatUid': chat.uid, 'participantUid': participant.uid},
    ).then((resp) {
      final chatFromDb = ObxInit.obx.chats.get(chat.id);
      if (chatFromDb == null) {
        completer.completeError(false);
      }
      chatFromDb!.participants.removeWhere((p) => p.uid == participant.uid);
      ObxInit.obx.chats.put(chatFromDb);
      completer.complete(true);
    }).catchError((error) {
      completer.completeError(false);
    });
  }

  leaveChat({required String chatUid}) {
    AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.leaveChat,
      payload: {
        'chatUid': chatUid,
      },
    ).then((resp) {
      deleteChat(chatUid: chatUid, skipNotify: true);
    });
  }

  updateChatFromResp(Chat chat) async {
    final query = ObxInit.obx.chats.query(Chat_.uid.equals(chat.uid)).build();
    final Chat? chatInDb = query.findFirst();
    query.close();

    if (chatInDb != null) {
      checkKeys(chat);
      chat.id = chatInDb.id;
      ObxInit.obx.chats.put(chat);
    }
  }

  _doSyncForAllChats(List<Chat> chats) async {
    for (var chat in chats) {
      checkKeys(chat);
    }
  }

  /// Unified key exchange check for all chat types
  /// Delegates to GroupKeyExchange which handles both one-to-one and group chats
  checkKeys(Chat chat) async {
    await GroupKeyExchange.ensureGroupKey(chat.uid, chat.isOneToOne);
  }

  Future<bool> findContactChatAndDelete(
      {required String contactUid, bool skipNotify = false}) async {
    final chats = ObxInit.obx.chats.getAll();
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
    delete() async {
      final query = ObxInit.obx.chats.query(Chat_.uid.equals(chatUid)).build();
      final chatInDb = query.findFirst();
      query.close();
      if (chatInDb != null) {
        // Clean up all message files in background (fire-and-forget)
        final filePaths =
            await messageService.buildFilePathsForMessages(chatInDb.messages);
        if (filePaths.isNotEmpty) {
          messageService.deleteFiles(filePaths);
        }

        chatInDb.messages.clear();
        chatInDb.messages.applyToDb();
        ObxInit.obx.chats.remove(chatInDb.id);
      }
    }

    if (skipNotify == false) {
      return AppHttpClient.message(
        channel: SocketChannelTypes.chat,
        type: ChatEventTypes.deleteChat,
        payload: chatUid,
      ).then((resp) async {
        await delete();
      }).onError((error, stackTrace) async {
        if (error == 'No such chat found') {
          await delete();
        }
      });
    } else {
      await delete();
    }
  }

  updateChatLastSeen({String? chatUid}) {
    AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.updateChatLastSeen,
      payload: chatUid ?? 'all',
    );
  }

  getChat({int? chatId, String? chatUid}) {
    if (chatId != null) {
      return ObxInit.obx.chats.get(chatId);
    } else if (chatUid != null) {
      final query = ObxInit.obx.chats.query(Chat_.uid.equals(chatUid)).build();
      final chat = query.findFirst();
      query.close();
      return chat;
    } else {
      return null;
    }
  }

  // ====== Update Chat (name/avatar) ======

  Future<Chat> updateChat({
    required String chatUid,
    String? name,
    Map<String, dynamic>? avatar,
  }) async {
    final payload = <String, dynamic>{'chatUid': chatUid};
    if (name != null) payload['name'] = name;
    if (avatar != null) {
      payload['avatar'] = avatar;
    }

    final resp = await AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.updateChat,
      payload: payload,
    );
    final Chat chat = Chat.fromJson(resp['chat']);
    await updateChatFromResp(chat);
    return chat;
  }

  // ====== Invite Link Methods ======

  Future<InviteLink> generateInviteLink({
    required String chatUid,
    required String type, // 'permanent' or 'one_time'
  }) async {
    final resp = await AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.generateInviteLink,
      payload: {'chatUid': chatUid, 'type': type},
    );
    // Update local chat with new invite links
    if (resp['chat'] != null) {
      addChat(Chat.fromJson(resp['chat']));
    }
    return InviteLink.fromJson(resp['inviteLink']);
  }

  Future<void> revokeInviteLink({
    required String chatUid,
    required String token,
  }) async {
    final resp = await AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.revokeInviteLink,
      payload: {'chatUid': chatUid, 'token': token},
    );
    if (resp['chat'] != null) {
      addChat(Chat.fromJson(resp['chat']));
    }
  }

  Future<Chat> joinChatViaInvite({required String token}) async {
    final resp = await AppHttpClient.message(
      channel: SocketChannelTypes.chat,
      type: ChatEventTypes.joinViaInvite,
      payload: {'token': token},
    );
    final Chat chat =
        addChat(Chat.fromJson(resp['chat']), isNewlyCreated: true);
    return chat;
  }
}
