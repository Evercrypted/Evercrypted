import 'dart:async';

import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';

import 'message_isar.dart';

class MessageService {
  StreamSubscription? fbListener;

  String? firebaseuserId = FirebaseAuth.instance.currentUser?.uid;

  void startListeningAndWritingToDB(
      Chat chatRoom, DateTime? lastMessageTime) async {
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
        .sortByCreatedAtMSEDesc()
        .offset(pageKey * pageSize)
        .limit(pageSize)
        .findAllSync()
        .toList();
  }

  Future<Message> sendMessage(dynamic message, String chatUid) async {
    Message messageToSend;
    if (message is String) {
      messageToSend = Message(
        authorId: firebaseuserId!,
        text: message,
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: chatUid,
      );
    } else {
      messageToSend = Message(
        authorId: firebaseuserId!,
        text: message['crypted'],
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: chatUid,
        iv: message['iv'],
        mac: message['mac'],
        isEncrypted: true,
      );
    }
    Completer<Message> complete = Completer();
    ChatSocket.instance
        .emitWAck(SocketChannelTypes.message, MessageEventTypes.sendMessage,
            messageToSend.toJson())
        .then((resp) {
      messageToSend.uid = resp['messageUid'];
      writeNewMessageToIsar(messageToSend).then((value) {
        complete.complete(messageToSend);
      });
    });
    return complete.future;
  }

  writeNewMessageToIsar(Message message) async {
    final isar = Isar.getInstance();
    return isar?.writeTxn(() async {
      await isar.messages.put(message);
    });
  }

  void stopListening() {
    fbListener?.cancel();
  }
}
