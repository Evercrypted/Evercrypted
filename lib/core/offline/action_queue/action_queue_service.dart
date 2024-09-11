import 'dart:convert';
import 'package:evercrypted/core/entities/message/message_isar.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:isar/isar.dart';

class ActionQueueService {
  MessageService messageService = MessageService();

  processQueue() async {
    final isar = Isar.getInstance();
    final queue = await isar?.actionQueues.where().findAll();
    if (queue != null) {
      dynamic result;
      for (var action in queue) {
        if (action.isHttp) {
          if (action.channel == 'files') {
            if (action.type == MessageEventTypes.sendFile) {
              final String? file =
                  await messageService.getMessageFile(queueId: action.id);
              if (file != null) {
                result = await messageService.sendFile(
                  isFromQueue: true,
                  queueId: action.id,
                  file: file,
                  payload: action.payload,
                );
              }
            }
          }
        } else {
          result = await ChatSocket.emitWAck(
            action.channel,
            action.type,
            json.decode(action.payload),
            isFromQueue: true,
          );
        }
        if (result != null) {
          if ((action.channel == SocketChannelTypes.message) &&
              result['messageUid'] != null) {
            Message? msg = isar?.messages
                .where()
                .queueIdEqualTo(action.id)
                .findFirstSync();
            if (msg != null) {
              await isar?.writeTxn(() async {
                msg.successfullySent = true;
                msg.uid = result['messageUid'];
                await isar.messages.put(msg);
              });
            }
          } else {
            await isar?.writeTxn(() async {
              await isar.actionQueues.delete(action.id);
            });
          }
        }
      }
    }
  }
}
