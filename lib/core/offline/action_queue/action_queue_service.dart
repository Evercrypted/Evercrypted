import 'dart:async';
import 'dart:convert';
import 'package:evercrypted/core/cryptography/base_key.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/objectbox.g.dart';

import 'package:rxdart/rxdart.dart';

class ActionQueueService {
  MessageService messageService = MessageService();
  bool isProcessing = false;
  static const int maxRetries = 3;

  // Global BehaviorSubject for message status updates
  static final BehaviorSubject<Message> messageStatusUpdatesSubject =
      BehaviorSubject<Message>();

  processQueue() async {
    // Prevent multiple simultaneous processing
    if (isProcessing) {
      return;
    }

    // Check if we're actually connected before processing
    if (ChatSocket.isConnected != true || ChatSocket.key == null) {
      return;
    }

    isProcessing = true;

    try {
      // Add a small delay to ensure connection is fully stabilized
      await Future.delayed(Duration(milliseconds: 500));

      // Double-check connection after delay
      if (ChatSocket.isConnected != true || ChatSocket.key == null) {
        return;
      }

      // Ensure HTTP client has proper auth headers with retry logic
      int authRetries = 0;
      const maxAuthRetries = 3;
      while (authRetries < maxAuthRetries) {
        try {
          await AppHttpClient.addAuth();
          break; // Success, exit retry loop
        } catch (e) {
          authRetries++;

          if (authRetries >= maxAuthRetries) {
            throw Exception(
                'Failed to initialize HTTP client after $maxAuthRetries attempts');
          }
          await Future.delayed(
              Duration(milliseconds: 200 * authRetries)); // Exponential backoff
        }
      }

      // First, clean up any orphaned messages
      await cleanupOrphanedMessages();

      final queue = ObxInit.obx.actionQueues.getAll();

      if (queue.isNotEmpty) {
        // First pass: Handle messages pending key exchange
        final pendingKeyMessages =
            queue.where((a) => a.type == 'sendMessagePendingKey').toList();
        if (pendingKeyMessages.isNotEmpty) {
          await BaseKey.processAllPendingMessages();
        }

        // Second pass: Process remaining queued actions
        for (var action in queue) {
          try {
            // Skip messages already processed in first pass
            if (action.type == 'sendMessagePendingKey') {
              continue;
            }

            // Check connection before each action
            if (ChatSocket.isConnected != true || ChatSocket.key == null) {
              break;
            }

            dynamic result;

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
                } else {
                  // Update message status and remove action if file is missing
                  await _handleFailedAction(action, 'File not found');
                  continue;
                }
              }
            } else {
              result = await AppHttpClient.message(
                channel: action.channel,
                type: action.type,
                payload: json.decode(action.payload),
                isFromQueue: true,
              );
            }

            // Process successful result
            if (result != null) {
              if ((action.channel == SocketChannelTypes.message) &&
                  result != null &&
                  result['messageUid'] != null) {
                final query = ObxInit.obx.messages
                    .query(Message_.queueId.equals(action.id))
                    .build();
                final Message? msg = query.findFirst();
                query.close();
                if (msg != null) {
                  // Check if a message with this messageUid already exists
                  final existingQuery = ObxInit.obx.messages
                      .query(Message_.uid.equals(result['messageUid']))
                      .build();
                  final existingMessage = existingQuery.findFirst();
                  existingQuery.close();

                  if (existingMessage != null && existingMessage.id != msg.id) {
                    // A message with this UID already exists (probably sent via socket)
                    // Just remove the queued duplicate

                    ObxInit.obx.messages.remove(msg.id);
                  } else {
                    // Update the queued message with server response
                    msg.successfullySent = true;
                    msg.uid = result['messageUid'];
                    msg.uniqueId = msg.chatUid + result['messageUid'];
                    msg.queueId =
                        null; // Clear queue ID since it's no longer queued
                    msg.couldNotSend = false;
                    msg.error = null;
                    ObxInit.obx.messages.put(msg);

                    // Notify UI about the status update
                    messageStatusUpdatesSubject.add(msg);
                  }
                }
              }
              // Remove action from queue after successful processing
              ObxInit.obx.actionQueues.remove(action.id);
            } else {
              // Handle null result as failure
              await _handleFailedAction(
                  action, 'Received null result from server');
            }
          } catch (error) {
            // Check if it's a connection error
            if (error.toString().contains('Connection') ||
                error.toString().contains('RhttpConnectionException')) {
              break; // Stop processing on connection errors
            }

            await _handleFailedAction(action, error.toString());
          }
        }
      }
    } finally {
      isProcessing = false;
    }
  }

  /// Handle failed action by updating message status and managing retries
  Future<void> _handleFailedAction(
      ActionQueue action, String errorMessage) async {
    // Check if this is a message-related action
    if (action.channel == SocketChannelTypes.message ||
        action.channel == 'files') {
      final query = ObxInit.obx.messages
          .query(Message_.queueId.equals(action.id))
          .build();
      final Message? msg = query.findFirst();
      query.close();

      if (msg != null) {
        // Update message status to reflect failure
        msg.successfullySent = false;
        msg.couldNotSend = true;
        msg.error = 'Failed to send: $errorMessage';
        ObxInit.obx.messages.put(msg);
      }
    }

    // Remove the failed action from queue
    ObxInit.obx.actionQueues.remove(action.id);
  }

  /// Clean up orphaned messages that have queueId but no corresponding queue item
  Future<void> cleanupOrphanedMessages() async {
    // Get all messages with queueId
    final query =
        ObxInit.obx.messages.query(Message_.queueId.notNull()).build();
    final messagesWithQueueId = query.find();
    query.close();

    for (var message in messagesWithQueueId) {
      if (message.queueId != null) {
        // Check if queue item still exists
        final queueItem = ObxInit.obx.actionQueues.get(message.queueId!);
        if (queueItem == null) {
          // Queue item doesn't exist, update message status
          if (!message.successfullySent) {
            message.couldNotSend = true;
            message.error = 'Message was not sent (queue item missing)';
            message.queueId = null;
            ObxInit.obx.messages.put(message);
          }
        }
      }
    }
  }
}
