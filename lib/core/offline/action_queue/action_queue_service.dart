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
import 'package:flutter/foundation.dart';
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
      debugPrint('ActionQueueService: Already processing queue');
      return;
    }

    // Check if we're actually connected before processing
    if (ChatSocket.isConnected != true || ChatSocket.key == null) {
      debugPrint(
          'ActionQueueService: Not connected or no encryption key, skipping queue processing');
      return;
    }

    isProcessing = true;

    try {
      // Add a small delay to ensure connection is fully stabilized
      await Future.delayed(Duration(milliseconds: 500));

      // Double-check connection after delay
      if (ChatSocket.isConnected != true || ChatSocket.key == null) {
        debugPrint(
            'ActionQueueService: Connection lost during delay, aborting queue processing');
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
          debugPrint(
              'ActionQueueService: addAuth failed (attempt $authRetries/$maxAuthRetries): $e');
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
      debugPrint(
          'ActionQueueService: Processing ${queue.length} queued actions');

      if (queue.isNotEmpty) {
        // First pass: Handle messages pending key exchange
        final pendingKeyMessages = queue.where((a) => a.type == 'sendMessagePendingKey').toList();
        if (pendingKeyMessages.isNotEmpty) {
          debugPrint('userLog: Found ${pendingKeyMessages.length} messages pending key exchange in action queue, processing...');
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
              debugPrint(
                  'ActionQueueService: Connection lost during processing, stopping');
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
                  debugPrint(
                      'ActionQueueService: File not found for queue id ${action.id}');
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
              debugPrint(
                  'ActionQueueService: Successfully processed action ${action.id}');
              debugPrint('ActionQueueService: Result: $result');

              if ((action.channel == SocketChannelTypes.message) &&
                  result != null &&
                  result['messageUid'] != null) {
                final query = ObxInit.obx.messages
                    .query(Message_.queueId.equals(action.id))
                    .build();
                final Message? msg = query.findFirst();
                query.close();
                if (msg != null) {
                  debugPrint(
                      'ActionQueueService: Updating message ${msg.id} with uid ${result['messageUid']}');

                  // Check if a message with this messageUid already exists
                  final existingQuery = ObxInit.obx.messages
                      .query(Message_.uid.equals(result['messageUid']))
                      .build();
                  final existingMessage = existingQuery.findFirst();
                  existingQuery.close();

                  if (existingMessage != null && existingMessage.id != msg.id) {
                    // A message with this UID already exists (probably sent via socket)
                    // Just remove the queued duplicate
                    debugPrint(
                        'ActionQueueService: Message with uid ${result['messageUid']} already exists, removing queued duplicate');
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

                    debugPrint(
                        'ActionQueueService: Message ${msg.id} updated successfully');
                  }
                } else {
                  debugPrint(
                      'ActionQueueService: No message found with queueId ${action.id}');
                }
              } else {
                debugPrint(
                    'ActionQueueService: Result missing messageUid or not a message channel. Channel: ${action.channel}, payload: $result');
              }
              // Remove action from queue after successful processing
              ObxInit.obx.actionQueues.remove(action.id);
              debugPrint(
                  'ActionQueueService: Removed action ${action.id} from queue');
            } else {
              // Handle null result as failure
              await _handleFailedAction(
                  action, 'Received null result from server');
            }
          } catch (error) {
            debugPrint(
                'ActionQueueService: Error processing action ${action.id}: $error');

            // Check if it's a connection error
            if (error.toString().contains('Connection') ||
                error.toString().contains('RhttpConnectionException')) {
              debugPrint(
                  'ActionQueueService: Connection error detected, stopping queue processing');
              break; // Stop processing on connection errors
            }

            await _handleFailedAction(action, error.toString());
          }
        }
      }
    } catch (error) {
      debugPrint('ActionQueueService: Fatal error in processQueue: $error');
    } finally {
      isProcessing = false;
    }
  }

  /// Handle failed action by updating message status and managing retries
  Future<void> _handleFailedAction(
      ActionQueue action, String errorMessage) async {
    try {
      // Check if this is a message-related action
      if (action.channel == SocketChannelTypes.message ||
          action.channel == 'files') {
        final query =
            ObxInit.obx.messages.query(Message_.queueId.equals(action.id)).build();
        final Message? msg = query.findFirst();
        query.close();

        if (msg != null) {
          // Update message status to reflect failure
          msg.successfullySent = false;
          msg.couldNotSend = true;
          msg.error = 'Failed to send: $errorMessage';
          ObxInit.obx.messages.put(msg);

          debugPrint(
              'ActionQueueService: Updated message ${msg.id} status to failed');
        }
      }

      // Remove the failed action from queue
      ObxInit.obx.actionQueues.remove(action.id);
      debugPrint(
          'ActionQueueService: Removed failed action ${action.id} from queue');
    } catch (e) {
      debugPrint(
          'ActionQueueService: Error handling failed action ${action.id}: $e');
    }
  }

  /// Clean up orphaned messages that have queueId but no corresponding queue item
  Future<void> cleanupOrphanedMessages() async {
    try {
      // Get all messages with queueId
      final query = ObxInit.obx.messages.query(Message_.queueId.notNull()).build();
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
              debugPrint(
                  'ActionQueueService: Cleaned up orphaned message ${message.id}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('ActionQueueService: Error cleaning up orphaned messages: $e');
    }
  }
}
