import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rhttp/rhttp.dart';

import 'message_isar.dart';

class MessageService {
  String? userId = Auth.user?.uid;

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

  Future<List<Message>> getMessagesFromDB(
      String chatUid, int pageKey, int pageSize) async {
    final isar = Isar.getInstance();
    if (pageKey == 0) {
      return isar!.messages
          .where()
          .chatUidEqualTo(chatUid)
          .sortByCreatedAtMSEDesc()
          .limit(pageSize)
          .findAllSync()
          .toList();
    } else {
      return isar!.messages
          .where()
          .chatUidEqualTo(chatUid)
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
        authorId: userId!,
        text: message,
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: chatUid,
      );
    } else {
      messageToSend = Message(
        authorId: userId!,
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

  dynamic checkIfSocketConnectedAndQueueIfNeeded(
      payload, file, isFromQueue) async {
    final completer = Completer<dynamic>();
    Future<int> saveActionForLater() async {
      final writingToQueueCompleter = Completer<int>();
      final action = ActionQueue(
          isHttp: true,
          channel: 'files',
          type: MessageEventTypes.sendFile,
          payload: json.encode(payload),
          createdAtMSE: DateTime.now().millisecondsSinceEpoch);
      final isar = Isar.getInstance();
      isar?.writeTxn(() async {
        final int queuedItemId = await isar.actionQueues.put(action);
        await saveFile(file: file, queueId: queuedItemId);
        writingToQueueCompleter.complete(queuedItemId);
      });
      return writingToQueueCompleter.future;
    }

    if (ChatSocket.socket?.connected != true ||
        ChatSocket.isConnected == null ||
        ChatSocket.isConnected == false) {
      final int queuedItemId = await saveActionForLater();
      completer.complete({'status': 'queued', 'queuedItemId': queuedItemId});
    } else if (isFromQueue) {
      completer.complete(true);
    } else {
      completer.complete(false);
    }
    return completer.future;
  }

  deleteFile({String? chatUid, String? msgUid, int? queueId}) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = queueId != null
        ? '${directory.path}/$queueId'
        : '${directory.path}/$chatUid/$msgUid';
    if (File(path).existsSync()) {
      File(path).deleteSync();
    }
  }

  getMessageFile({String? chatUid, String? msgUid, int? queueId}) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = queueId != null
        ? '${directory.path}/$queueId'
        : '${directory.path}/$chatUid/$msgUid';
    if (await File(path).exists()) {
      final fileAtPath = File(path);
      return await fileAtPath.readAsString();
    } else {
      return null;
    }
  }

  saveFile(
      {required String file,
      String? chatUid,
      String? msgUid,
      int? queueId}) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = queueId != null
        ? '${directory.path}/$queueId'
        : '${directory.path}/$chatUid/$msgUid';
    final fileAtPath = File(path);
    await fileAtPath.writeAsString(file);
    return path;
  }

  Future<dynamic> sendFile(
      {Message? message,
      required String file,
      dynamic payload,
      bool isFromQueue = false,
      int? queueId}) async {
    Completer<Message> complete = Completer();
    dynamic crypted;
    if (isFromQueue) {
      final decoded = json.decode(payload);
      crypted = encodePayload(decoded, ChatSocket.key);
      HttpClient.client
          .post('/files/${MessageEventTypes.sendFile}',
              body: HttpBody.json(crypted))
          .then((resp) async {
        final payload = await decodePayload(
          resp.bodyToJson['crypted'],
          resp.bodyToJson['iv'],
          resp.bodyToJson['mac'],
          ChatSocket.key,
        );
        final msg = Message.fromJson(decoded['message']);
        msg.uid = payload['payload']['messageUid'];
        msg.uniqueId = msg.chatUid + payload['payload']['messageUid'];
        msg.successfullySent = true;
        msg.queueId = null;
        msg.filepath = await saveFile(
            file: decoded['file'], chatUid: msg.chatUid, msgUid: msg.uid);
        deleteFile(queueId: queueId!);
        writeNewMessageToIsar(msg).then((value) {
          complete.complete(message);
        });
      }).onError((error, stackTrace) {
        complete.completeError(error!);
      });
    } else {
      final payload = {
        'message': message!.toJson(),
      };
      final saveToQueueIfNeeded = await checkIfSocketConnectedAndQueueIfNeeded(
          json.encode(payload), file, isFromQueue);
      if (saveToQueueIfNeeded == true) {
        complete.completeError(
            'Could not connect to server, please check your internet connection.');
      } else if (saveToQueueIfNeeded == false) {
        crypted = await encodePayload(payload, ChatSocket.key);
        HttpClient.client
            .post('/files/${MessageEventTypes.sendFile}',
                body: HttpBody.json(crypted))
            .then((resp) async {
          final payload = await decodePayload(
            resp.bodyToJson['crypted'],
            resp.bodyToJson['iv'],
            resp.bodyToJson['mac'],
            ChatSocket.key,
          );
          if (payload['status'] == 'ok') {
            message.uid = payload['payload']['messageUid'];
            message.uniqueId =
                message.chatUid + payload['payload']['messageUid'];
            message.successfullySent = true;
            message.filepath = await saveFile(
                file: file, chatUid: message.chatUid, msgUid: message.uid);
            writeNewMessageToIsar(message).then((value) {
              complete.complete(message);
            });
          }
        }).onError((error, stackTrace) {
          complete.completeError(error!);
        });
      } else if (saveToQueueIfNeeded['status'] == 'queued') {
        message.successfullySent = false;
        message.queueId = saveToQueueIfNeeded['queuedItemId'];
        message.uid = DateTime.now().millisecondsSinceEpoch.toString() +
            saveToQueueIfNeeded['queuedItemId'].toString();
        message.uniqueId = DateTime.now().millisecondsSinceEpoch.toString() +
            message.chatUid +
            saveToQueueIfNeeded['queuedItemId'].toString();
        writeNewMessageToIsar(message).then((value) {
          complete.complete(message);
        });
      }
    }
    return complete.future;
  }

  downloadFile(String chatUid, String messageUid) {
    final completer = Completer();
    HttpClient.client.get('/files/${MessageEventTypes.downloadFile}', query: {
      'chatUid': chatUid,
      'messageUid': messageUid
    }).then((resp) async {
      print(resp);
      // final payload = await decodePayload(
      //   resp.bodyToJson['crypted'],
      //   resp.bodyToJson['iv'],
      //   resp.bodyToJson['mac'],
      //   ChatSocket.key,
      // );
    }).onError((error, stackTrace) {
      completer.completeError(error!);
    });
    return completer.future;
  }

  writeNewMessageToIsar(Message message) async {
    final isar = Isar.getInstance();
    Chat chat = isar!.chats
        .where()
        .filter()
        .uidEqualTo(message.chatUid)
        .findFirstSync()!;
    chat.lastMessageTime = DateTime.now();
    return isar.writeTxn(() async {
      await isar.messages.put(message);
      await isar.chats.put(chat);
    });
  }
}
