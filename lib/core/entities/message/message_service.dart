import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:evercrypted/core/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_service.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:path_provider/path_provider.dart';

import 'message_model.dart';

import 'package:evercrypted/core/obx_init.dart';

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
    final query = ObxInit.obx.messages
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
      dynamic message, String chatUid, bool withBaseKey, {int? queueId}) async {
    Message messageToSend;

    // Check if we're updating an existing optimistic message
    if (queueId != null) {
      final optimisticQuery = ObxInit.obx.messages
          .query(Message_.queueId.equals(queueId))
          .build();
      final existingMessage = optimisticQuery.findFirst();
      optimisticQuery.close();

      if (existingMessage != null) {
        messageToSend = existingMessage;
        // Update with encrypted content
        if (message is String) {
          messageToSend.text = message;
        } else {
          messageToSend.text = message['crypted'];
          messageToSend.iv = message['iv'];
          messageToSend.mac = message['mac'];
          messageToSend.isEncrypted = true;
        }
        messageToSend.withBaseKey = withBaseKey;
      } else {
        // Fallback: create new message if optimistic message not found
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
      }
    } else {
      // Create new message (normal flow)
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
    }

    Completer<Message> complete = Completer();
    AppHttpClient.message(
      channel: SocketChannelTypes.message,
      type: MessageEventTypes.sendMessage,
      payload: messageToSend.toJson(),
    ).then((resp) {
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
        messageToSend.queueId = null; // Clear queueId when successfully sent
      }

      // Update existing message or write new one
      if (queueId != null && messageToSend.id > 0) {
        ObxInit.obx.messages.put(messageToSend);
        // Emit status update for UI to react
        ActionQueueService.messageStatusUpdatesSubject.add(messageToSend);
        complete.complete(messageToSend);
      } else {
        writeNewMessageToObx(messageToSend).then((value) {
          // Emit status update for UI to react
          ActionQueueService.messageStatusUpdatesSubject.add(messageToSend);
          complete.complete(messageToSend);
        });
      }
    }).onError((error, stackTrace) {
      messageToSend.successfullySent = false;
      messageToSend.error = 'Could not send message';

      // Update existing message or write new one
      if (queueId != null && messageToSend.id > 0) {
        ObxInit.obx.messages.put(messageToSend);
        complete.complete(messageToSend);
      } else {
        writeNewMessageToObx(messageToSend).then((value) {
          complete.complete(messageToSend);
        });
      }
      complete.completeError(error!);
    });
    return complete.future;
  }

  sendGroupKeyRequest(Message message) {
    AppHttpClient.message(
      channel: SocketChannelTypes.message,
      type: MessageEventTypes.sendMessage,
      payload: message.toJson(),
    );
  }

  dynamic checkIfSocketConnectedAndQueueIfNeeded(payload, file) async {
    final completer = Completer<dynamic>();
    Future<int> saveActionForLater() async {
      final writingToQueueCompleter = Completer<int>();
      final action = ActionQueue(
          channel: 'files',
          type: MessageEventTypes.sendFile,
          payload: json.encode(payload),
          createdAtMSE: DateTime.now().millisecondsSinceEpoch);
      final int id = ObxInit.obx.actionQueues.put(action);
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

  /// Batch delete multiple files for improved performance
  /// Returns a map of file paths to deletion results (true = success, false = failed)
  Future<Map<String, bool>> deleteFiles(List<String> filePaths) async {
    final Map<String, bool> results = {};

    if (filePaths.isEmpty) {
      return results;
    }

    // Process files in parallel batches to improve performance
    const int batchSize = 10;
    final List<List<String>> batches = [];

    for (int i = 0; i < filePaths.length; i += batchSize) {
      final end =
          (i + batchSize < filePaths.length) ? i + batchSize : filePaths.length;
      batches.add(filePaths.sublist(i, end));
    }

    for (final batch in batches) {
      final List<Future<void>> deletionFutures = batch.map((filePath) async {
        try {
          if (File(filePath).existsSync()) {
            await File(filePath).delete();
            results[filePath] = true;
          } else {
            results[filePath] = true; // File doesn't exist = success
          }
        } catch (error) {
          debugPrint('Failed to delete file $filePath: $error');
          results[filePath] = false;
        }
      }).toList();

      // Wait for current batch to complete before processing next batch
      await Future.wait(deletionFutures);
    }

    final successCount = results.values.where((success) => success).length;
    final failCount = results.length - successCount;

    if (failCount > 0) {
      debugPrint(
          'Batch file deletion completed: $successCount succeeded, $failCount failed');
    } else {
      debugPrint(
          'Batch file deletion completed: all $successCount files deleted successfully');
    }

    return results;
  }

  /// Helper method to build file paths for messages
  Future<List<String>> buildFilePathsForMessages(List<Message> messages) async {
    final directory = await getApplicationDocumentsDirectory();
    final List<String> filePaths = [];

    for (final message in messages) {
      if (message.filepath != null && message.filepath!.isNotEmpty) {
        filePaths.add(message.filepath!);
      } else if (message.queueId != null) {
        filePaths.add('${directory.path}/${message.queueId}');
      } else if (message.uid != null) {
        filePaths.add('${directory.path}/${message.chatUid}/${message.uid}');
      }
    }

    return filePaths;
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
      int? queueId,
      int? optimisticMessageQueueId}) async {
    Completer<Message> complete = Completer();

    // Check if we need to update an existing optimistic message
    Message? existingOptimisticMessage;
    if (optimisticMessageQueueId != null) {
      final optimisticQuery = ObxInit.obx.messages
          .query(Message_.queueId.equals(optimisticMessageQueueId))
          .build();
      existingOptimisticMessage = optimisticQuery.findFirst();
      optimisticQuery.close();

      if (existingOptimisticMessage != null && message != null) {
        // Update the existing optimistic message with the actual file data
        message = existingOptimisticMessage
          ..iv = message.iv
          ..mac = message.mac
          ..messageType = message.messageType
          ..text = message.text
          ..isEncrypted = true
          ..withBaseKey = message.withBaseKey;
      }
    }

    if (isFromQueue) {
      final decoded = json.decode(payload);
      final msg = Message.fromJson(decoded['message']);
      AppHttpClient.message(
              channel: SocketChannelTypes.message,
              type: MessageEventTypes.sendFile,
              payload: decoded)
          .then((resp) async {
        // Check if a message with this messageUid already exists
        final existingQuery =
            ObxInit.obx.messages.query(Message_.uid.equals(resp['messageUid'])).build();
        final existingMessage = existingQuery.findFirst();
        existingQuery.close();

        if (existingMessage != null && existingMessage.id != msg.id) {
          // A message with this UID already exists, remove the queued duplicate
          final msgIdToRemove = msg.id;
          ObxInit.obx.messages.remove(msgIdToRemove);
          deleteFile(queueId: queueId!);
          debugPrint(
              'MessageService: Message with uid ${resp['messageUid']} already exists, removed queued duplicate');
        } else {
          // Update the queued message with server response
          msg.uid = resp['messageUid'];
          msg.uniqueId = msg.chatUid + resp['messageUid'];
          msg.successfullySent = true;
          msg.queueId = null;
          msg.filepath = await saveFile(
              file: decoded['file'], chatUid: msg.chatUid, msgUid: msg.uid);
          deleteFile(queueId: queueId!);
          writeNewMessageToObx(msg).then((value) {
            // Emit status update for UI to react
            ActionQueueService.messageStatusUpdatesSubject.add(msg);
            complete.complete(message);
          });
        }
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
      debugPrint('DEBUG: Sending file: $file');
      debugPrint('DEBUG: message: ${message?.toJson()}');

      if (message == null) {
        complete.completeError('Message is null');
        return complete.future;
      }

      // Capture non-null message for use in async callbacks
      final messageToSend = message;

      final saveToQueueIfNeeded = await checkIfSocketConnectedAndQueueIfNeeded(
          {'message': messageToSend.toJson(), 'file': file}, file);
      if (saveToQueueIfNeeded == false) {
        AppHttpClient.message(
          channel: SocketChannelTypes.message,
          type: MessageEventTypes.sendFile,
          payload: {
            'message': messageToSend.toJson(),
            'file': file,
          },
        ).then((resp) async {
          // Check if a message with this messageUid already exists
          final existingQuery = ObxInit.obx.messages
              .query(Message_.uid.equals(resp['messageUid']))
              .build();
          final existingMessage = existingQuery.findFirst();
          existingQuery.close();

          if (existingMessage != null && existingMessage.id != messageToSend.id) {
            // A message with this UID already exists, remove this duplicate
            final msgIdToRemove = messageToSend.id;
            ObxInit.obx.messages.remove(msgIdToRemove);
            debugPrint(
                'MessageService: Message with uid ${resp['messageUid']} already exists, removed duplicate');
          } else {
            // Update the message with server response
            messageToSend.uid = resp['messageUid'];
            messageToSend.uniqueId = messageToSend.chatUid + resp['messageUid'];
            messageToSend.successfullySent = true;
            messageToSend.queueId = null; // Clear queueId when successfully sent
            messageToSend.filepath = await saveFile(
                file: file, chatUid: messageToSend.chatUid, msgUid: messageToSend.uid);

            // If updating optimistic message, use put; otherwise use writeNewMessageToObx
            if (optimisticMessageQueueId != null && messageToSend.id > 0) {
              ObxInit.obx.messages.put(messageToSend);
              // Emit status update for UI to react
              ActionQueueService.messageStatusUpdatesSubject.add(messageToSend);
              complete.complete(messageToSend);
            } else {
              writeNewMessageToObx(messageToSend).then((value) {
                // Emit status update for UI to react
                ActionQueueService.messageStatusUpdatesSubject.add(messageToSend);
                complete.complete(messageToSend);
              });
            }
          }
        }).onError((error, stackTrace) async {
          messageToSend.successfullySent = false;
          messageToSend.error = 'Could not send file';
          messageToSend.filepath = await saveFile(
              file: file,
              chatUid: messageToSend.chatUid,
              msgUid: DateTime.now().microsecondsSinceEpoch.toString());

          // If updating optimistic message, use put; otherwise use writeNewMessageToObx
          if (optimisticMessageQueueId != null && messageToSend.id > 0) {
            ObxInit.obx.messages.put(messageToSend);
            complete.complete(messageToSend);
          } else {
            writeNewMessageToObx(messageToSend).then((value) {
              complete.complete(messageToSend);
            });
          }
        });
      } else if (saveToQueueIfNeeded['status'] == 'queued') {
        messageToSend.successfullySent = false;
        messageToSend.queueId = saveToQueueIfNeeded['queuedItemId'];
        messageToSend.uid = DateTime.now().millisecondsSinceEpoch.toString() +
            saveToQueueIfNeeded['queuedItemId'].toString();
        messageToSend.uniqueId = DateTime.now().millisecondsSinceEpoch.toString() +
            messageToSend.chatUid +
            saveToQueueIfNeeded['queuedItemId'].toString();
        writeNewMessageToObx(messageToSend).then((value) {
          complete.complete(messageToSend);
        });
      }
    }
    return complete.future;
  }

  Future<String> downloadFile(
      String chatUid, String messageUid, String fileKey) async {
    final Completer<String> completer = Completer();
    AppHttpClient.message(
      channel: SocketChannelTypes.message,
      type: MessageEventTypes.downloadFile,
      payload: {
        'chatUid': chatUid,
        'messageUid': messageUid,
        'fileKey': fileKey,
      },
    ).then((resp) async {
      final Message message = getMessage(chatUid, messageUid);
      message.filepath = await saveFile(
          file: resp['file'], chatUid: chatUid, msgUid: messageUid);
      ObxInit.obx.messages.put(message);
      completer.complete(resp['file']);
    }).onError((error, stackTrace) {
      completer.completeError('Could not download file');
    });
    return completer.future;
  }

  getMessage(String chatUid, String messageUid) {
    final query = ObxInit.obx.messages
        .query(Message_.chatUid
            .equals(chatUid)
            .and(Message_.uid.equals(messageUid)))
        .build();
    final Message message = query.findFirst()!;
    query.close();
    return message;
  }

  writeNewMessageToObx(Message message) async {
    // Check if a message with this uid or uniqueId already exists
    final existingByUidQuery = message.uid != null
        ? ObxInit.obx.messages.query(Message_.uid.equals(message.uid!)).build()
        : null;
    final existingByUid = existingByUidQuery?.findFirst();
    existingByUidQuery?.close();

    final existingByUniqueIdQuery = message.uniqueId != null
        ? ObxInit.obx.messages
            .query(Message_.uniqueId.equals(message.uniqueId!))
            .build()
        : null;
    final existingByUniqueId = existingByUniqueIdQuery?.findFirst();
    existingByUniqueIdQuery?.close();

    if (existingByUid != null || existingByUniqueId != null) {
      debugPrint(
          'MessageService: Message with uid ${message.uid} or uniqueId ${message.uniqueId} already exists, skipping duplicate');
      return;
    }

    final query = ObxInit.obx.chats.query(Chat_.uid.equals(message.chatUid)).build();
    final Chat? chat = query.findFirst();
    query.close();

    if (chat != null) {
      chat.lastMessageTime = DateTime.now();
      chat.messages.add(message);
      ObxInit.obx.chats.put(chat);
    }
  }

  Future<void> deleteAllMessages(String chatUid) async {
    final query = ObxInit.obx.messages.query(Message_.chatUid.equals(chatUid)).build();
    final messages = query.find();

    if (messages.isEmpty) {
      query.close();
      return;
    }

    // Build file paths for batch deletion
    final filePaths = await buildFilePathsForMessages(messages);

    // Fire-and-forget file deletion - don't wait for completion
    if (filePaths.isNotEmpty) {
      deleteFiles(filePaths).catchError((error) {
        debugPrint('Background file deletion failed for chat $chatUid: $error');
        return <String, bool>{}; // Return empty map on error
      });
    }

    // Remove messages from database immediately without waiting for file deletion
    final messageIds = messages.map((m) => m.id).toList();
    ObxInit.obx.messages.removeMany(messageIds);
    query.close();
  }
}
