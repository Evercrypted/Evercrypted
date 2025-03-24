import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rhttp/rhttp.dart';

import 'message_model.dart';

import 'package:evercrypted/main.dart';

class MessageService {
  String? userId = Auth.user?.uid;

  // void syncMessages(List<Message> messages) async {
  //   try {
  //     await isar?.writeTxn(() async {
  //       await isar.messages.putAll(messages);
  //     });
  //   } catch (e) {
  //     //couldn't batch put, put one by one
  //   }

  //   for (var element in messages) {
  //     try {
  //       await isar?.writeTxn(() async {
  //         await isar.messages.put(element);
  //       });
  //     } catch (e) {
  //       //there is already a message with this uniqueid
  //     }
  //   }
  // }

  Future<List<Message>> getMessagesFromDB(
      int chatId, int pageKey, int pageSize) async {
    final query = obx.messages
        .query(Message_.chat.equals(chatId))
        .order(Message_.createdAtMSE, flags: Order.descending)
        .build();
    query.limit = pageSize;
    List<Message> result;
    if (pageKey == 0) {
      result = query.find();
    } else {
      query.offset = pageKey * pageSize;
      result = query.find();
    }
    query.close();
    return result;
  }

  Future<Message> sendMessage(
      dynamic message, String chatUid, bool withBaseKey) async {
    Message messageToSend;
    if (message is String) {
      messageToSend = Message(
        authorId: userId!,
        text: message,
        createdAtMSE: DateTime.now().millisecondsSinceEpoch,
        chatUid: chatUid,
        withBaseKey: withBaseKey,
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
        withBaseKey: withBaseKey,
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
      writeNewMessageToObx(messageToSend).then((value) {
        complete.complete(messageToSend);
      });
    }).onError((error, stackTrace) {
      messageToSend.successfullySent = false;
      messageToSend.error = 'Could not send message';
      writeNewMessageToObx(messageToSend).then((value) {
        complete.complete(messageToSend);
      });
      complete.completeError(error!);
    });
    return complete.future;
  }

  dynamic checkIfSocketConnectedAndQueueIfNeeded(payload, file) async {
    final completer = Completer<dynamic>();
    Future<int> saveActionForLater() async {
      final writingToQueueCompleter = Completer<int>();
      final action = ActionQueue(
          isHttp: true,
          channel: 'files',
          type: MessageEventTypes.sendFile,
          payload: json.encode(payload),
          createdAtMSE: DateTime.now().millisecondsSinceEpoch);
      final int id = obx.actionQueues.put(action);
      await saveFile(file: file, queueId: id);
      writingToQueueCompleter.complete(id);
      return writingToQueueCompleter.future;
    }

    if (ChatSocket.socket?.connected != true ||
        ChatSocket.isConnected == null ||
        ChatSocket.isConnected == false) {
      final int queuedItemId = await saveActionForLater();
      completer.complete({'status': 'queued', 'queuedItemId': queuedItemId});
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
      final fileString = await fileAtPath.readAsString();
      return fileString;
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
    File(path).createSync(recursive: true);
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
      final msg = Message.fromJson(decoded['message']);
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
        if (payload['status'] == 'ok') {
          msg.uid = payload['payload']['messageUid'];
          msg.uniqueId = msg.chatUid + payload['payload']['messageUid'];
          msg.successfullySent = true;
          msg.queueId = null;
          msg.filepath = await saveFile(
              file: decoded['file'], chatUid: msg.chatUid, msgUid: msg.uid);
        } else {
          msg.successfullySent = false;
          msg.error = 'Could not send file';
          msg.filepath = await saveFile(
              file: decoded['file'],
              chatUid: msg.chatUid,
              msgUid: DateTime.now().microsecondsSinceEpoch.toString());
        }
        deleteFile(queueId: queueId!);
        writeNewMessageToObx(msg).then((value) {
          complete.complete(message);
        });
      }).onError((error, stackTrace) async {
        msg.successfullySent = false;
        msg.error = 'Could not send file';
        msg.filepath = await saveFile(
            file: decoded['file'],
            chatUid: msg.chatUid,
            msgUid: DateTime.now().microsecondsSinceEpoch.toString());
        deleteFile(queueId: queueId!);
        writeNewMessageToObx(msg).then((value) {
          complete.complete(message);
        });
      });
    } else {
      final payload = {
        'message': message!.toJson(),
      };
      final saveToQueueIfNeeded = await checkIfSocketConnectedAndQueueIfNeeded(
          json.encode(payload), file);
      if (saveToQueueIfNeeded == false) {
        crypted = await encodePayload({
          ...payload,
          'file': file,
        }, ChatSocket.key);
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
          } else {
            message.successfullySent = false;
            message.error = 'Could not send file';
            message.filepath = await saveFile(
                file: file,
                chatUid: message.chatUid,
                msgUid: DateTime.now().microsecondsSinceEpoch.toString());
          }
          writeNewMessageToObx(message).then((value) {
            complete.complete(message);
          });
        }).onError((error, stackTrace) async {
          message.successfullySent = false;
          message.error = 'Could not send file';
          message.filepath = await saveFile(
              file: file,
              chatUid: message.chatUid,
              msgUid: DateTime.now().microsecondsSinceEpoch.toString());
          writeNewMessageToObx(message).then((value) {
            complete.complete(message);
          });
        });
      } else if (saveToQueueIfNeeded['status'] == 'queued') {
        message.successfullySent = false;
        message.queueId = saveToQueueIfNeeded['queuedItemId'];
        message.uid = DateTime.now().millisecondsSinceEpoch.toString() +
            saveToQueueIfNeeded['queuedItemId'].toString();
        message.uniqueId = DateTime.now().millisecondsSinceEpoch.toString() +
            message.chatUid +
            saveToQueueIfNeeded['queuedItemId'].toString();
        writeNewMessageToObx(message).then((value) {
          complete.complete(message);
        });
      }
    }
    return complete.future;
  }

  Future<String> downloadFile(String chatUid, String messageUid) async {
    final Completer<String> completer = Completer();
    final payload = await encodePayload({
      'chatUid': chatUid,
      'messageUid': messageUid,
    }, ChatSocket.key);
    HttpClient.client
        .post('/files/${MessageEventTypes.downloadFile}',
            body: HttpBody.json(payload))
        .then((resp) async {
      final respPayload = await decodePayload(
        resp.bodyToJson['crypted'],
        resp.bodyToJson['iv'],
        resp.bodyToJson['mac'],
        ChatSocket.key,
      );
      if (respPayload['status'] != 'success') {
        completer.completeError('Could not download file');
      } else {
        final Message message = getMessage(chatUid, messageUid);
        message.filepath = await saveFile(
            file: respPayload['file'], chatUid: chatUid, msgUid: messageUid);
        obx.messages.put(message);
        completer.complete(respPayload['file']);
      }
    }).onError((error, stackTrace) {
      completer.completeError('Could not download file');
    });
    return completer.future;
  }

  getMessage(String chatUid, String messageUid) {
    final query = obx.messages
        .query(Message_.chatUid
            .equals(chatUid)
            .and(Message_.uid.equals(messageUid)))
        .build();
    final Message message = query.findFirst()!;
    query.close();
    return message;
  }

  writeNewMessageToObx(Message message) async {
    final query = obx.chats.query(Chat_.uid.equals(message.chatUid)).build();
    final Chat chat = query.findFirst()!;
    query.close();
    chat.lastMessageTime = DateTime.now();
    chat.messages.add(message);
    obx.chats.put(chat);
  }

  Future<void> deleteAllMessages(String chatUid) async {
    final query = obx.messages.query(Message_.chatUid.equals(chatUid)).build();
    final messages = query.find();
    final messageIds = messages.map((m) => m.id).toList();
    obx.messages.removeMany(messageIds);
    query.close();
  }
}
