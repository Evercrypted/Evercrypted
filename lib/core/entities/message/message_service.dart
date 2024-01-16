import 'dart:async';

import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar/isar.dart';

import 'message_isar.dart';

class MessageService {
  StreamSubscription? fbListener;

  String? firebaseuserId = FirebaseAuth.instance.currentUser?.uid;

  void syncMessages(List<Message> messages) async {
    final isar = Isar.getInstance();

    try {
      await isar?.writeTxn(() async {
        await isar.messages.putAll(messages);
      });
    } catch (e) {
      //couldn't batch put, put one by one
    }

    for (var element in messages) {
      try {
        await isar?.writeTxn(() async {
          await isar.messages.put(element);
        });
      } catch (e) {
        //there is already a message with this uniqueid
      }
    }
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
      messageToSend.uniqueId = chatUid + resp['messageUid'];
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
