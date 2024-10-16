import 'dart:convert';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/objectbox.g.dart';

class ActionQueueService {
  MessageService messageService = MessageService();

  processQueue() async {
    final queue = obx.actionQueues.getAll();
    if (queue.isNotEmpty) {
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
            final query =
                obx.messages.query(Message_.queueId.equals(action.id)).build();
            final Message? msg = query.findFirst();
            query.close();
            if (msg != null) {
              msg.successfullySent = true;
              msg.uid = result['messageUid'];
              obx.messages.put(msg);
              obx.actionQueues.remove(action.id);
            }
          } else {
            obx.actionQueues.remove(action.id);
          }
        }
      }
    }
  }
}
