import 'dart:async';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:isar/isar.dart';

import 'message_isar.dart';

class MessageService {
  StreamSubscription? fbListener;

  String? firebaseuserId = Auth.user?.uid;

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
    if (pageKey == 0) {
      return isar!.messages
          .where()
          .sortByCreatedAtMSEDesc()
          .limit(pageSize)
          .findAllSync()
          .toList();
    } else {
      return isar!.messages
          .where()
          .sortByCreatedAtMSEDesc()
          .offset(pageKey * pageSize)
          .limit(pageSize)
          .findAllSync()
          .toList();
    }
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
    ChatSocket.emitWAck(SocketChannelTypes.message,
            MessageEventTypes.sendMessage, messageToSend.toJson())
        .then((resp) {
      if (resp['status'] == 'queued') {
        messageToSend.successfullySent = false;
        messageToSend.queueId = resp['queuedItemId'];
        messageToSend.uid = DateTime.now().millisecondsSinceEpoch.toString() +
            resp['queuedItemId'].toString();
        messageToSend.uniqueId =
            DateTime.now().millisecondsSinceEpoch.toString() +
                chatUid +
                resp['queuedItemId'].toString();
      } else {
        messageToSend.uid = resp['messageUid'];
        messageToSend.uniqueId = chatUid + resp['messageUid'];
        messageToSend.successfullySent = true;
      }
      writeNewMessageToIsar(messageToSend).then((value) {
        complete.complete(messageToSend);
      });
    }).onError((error, stackTrace) {
      complete.completeError(error!);
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
