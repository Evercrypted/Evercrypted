import 'dart:convert';
import 'package:evercrypted/core/entities/message/message_isar.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:isar/isar.dart';

class ActionQueueService {
  processQueue() async {
    final isar = Isar.getInstance();
    final queue = await isar?.actionQueues.where().findAll();
    if (queue != null) {
      for (var action in queue) {
        final result = await ChatSocket.instance.emitWAck(
          action.channel,
          action.type,
          json.decode(action.payload),
          isFromQueue: true,
        );
        if (result != null) {
          switch (action.channel) {
            case SocketChannelTypes.message:
              if (action.type == MessageEventTypes.sendMessage) {
                print(action.id);
                await isar?.writeTxn(() async {
                  await isar.messages
                      .where()
                      .queueIdEqualTo(action.id)
                      .findFirst()
                      .then((message) {
                    print(message!.toJson());
                    message.successfullySent = true;
                    message.uid = result['messageUid'];
                    isar.messages.put(message);
                                    });
                });
              }
          }
          await isar?.writeTxn(() async {
            await isar.actionQueues.delete(action.id);
          });
        }
      }
    }
  }
}
