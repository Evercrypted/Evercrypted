import 'dart:async';

import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:isar/isar.dart';

import 'message_isar.dart';

class MessageService {
  StreamSubscription? fbListener;

  void startListeningAndWritingToDB(Chat chatRoom, int? lastMessageTime) async {
    // final userId = FirebaseAuth.instance.currentUser?.uid;
    // final participantsToListenTo =
    //     chatRoom.participants!.where((element) => element != userId).toList();
    // final messagesCollection = FirebaseFirestore.instance
    //     .collection('chatRooms')
    //     .doc(chatRoom.uid)
    //     .collection('messages');
    // final messageRequests = lastMessageTime != null
    //     ? messagesCollection
    //         .where('authorId', whereIn: participantsToListenTo)
    //         .where('createdAtMSE', isGreaterThan: lastMessageTime)
    //     : messagesCollection.where('authorId', isNotEqualTo: userId);
    // final isar = Isar.getInstance();
    // fbListener = messageRequests.snapshots().listen((event) async {
    //   for (var change in event.docChanges) {
    //     if (change.type == DocumentChangeType.added) {
    //       final message = null;
    //       message.chatId = chatRoom.uid;
    //       final isInDb =
    //           isar!.messages.where().uidEqualTo(message.fbUid).countSync() > 0;
    //       if (!isInDb) {
    //         await isar.writeTxn(() async {
    //           await isar.messages.put(message);
    //         });
    //       }
    //     }
    //   }
    // });
  }

  Future<List<Message>> getMessagesFromDB(int pageKey, int pageSize) async {
    final isar = Isar.getInstance();
    return isar!.messages
        .where()
        .sortByTimestamp()
        .offset(pageKey * pageSize)
        .limit(pageSize)
        .findAllSync()
        .toList();
  }

  void sendMessage(Message message) async {
    final isar = Isar.getInstance();
    await isar?.writeTxn(() async {
      await isar.messages.put(message); // insert & update
    }).then((value) {
      // writeMessageToFB(message);
    });
  }

  void stopListening() {
    fbListener?.cancel();
  }
}
