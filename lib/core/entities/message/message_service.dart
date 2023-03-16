import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evercrypted/core/entities/chat-room/chat_room_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';

import 'message_isar.dart';

class MessageService {
  StreamSubscription? fbListener;

  void startListeningAndWritingToDB(
      ChatRoom chatRoom, int? lastMessageTime) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final participantsToListenTo =
        chatRoom.participants!.where((element) => element != userId).toList();
    final messagesCollection = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoom.fbUid)
        .collection('messages');
    final messageRequests = lastMessageTime != null
        ? messagesCollection
            .where('authorId', whereIn: participantsToListenTo)
            .where('createdAtMSE', isGreaterThan: lastMessageTime)
        : messagesCollection.where('authorId', isNotEqualTo: userId);
    final isar = Isar.getInstance() ?? await Isar.open([MessageSchema]);
    fbListener = messageRequests.snapshots().listen((event) async {
      for (var change in event.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final message = Message.fromJson(change.doc.id, change.doc.data()!);
          message.chatId = chatRoom.fbUid;
          final isInDb =
              isar.messages.where().fbUidEqualTo(message.fbUid).countSync() > 0;
          if (!isInDb) {
            await isar.writeTxn(() async {
              await isar.messages.put(message);
            });
          }
        }
      }
    });
  }

  Future<List<Message>> getMessagesFromDB(int pageKey, int pageSize) async {
    final isar = Isar.getInstance() ?? await Isar.open([MessageSchema]);
    return isar.messages
        .where()
        .sortByCreatedAtMSEDesc()
        .offset(pageKey * pageSize)
        .limit(pageSize)
        .findAllSync()
        .toList();
  }

  void sendMessage(Message message) async {
    final isar = Isar.getInstance() ?? await Isar.open([MessageSchema]);
    await isar.writeTxn(() async {
      await isar.messages.put(message); // insert & update
    }).then((value) {
      writeMessageToFB(message);
    });
  }

  void writeMessageToFB(Message message) {
    final messageCollection = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(message.chatId)
        .collection('messages');
    messageCollection.add(message.toJson());
  }

  void stopListening() {
    fbListener?.cancel();
  }
}
