import 'dart:convert';
import 'dart:math';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/base_key.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:flutter/foundation.dart';

class GroupKeyExchange {
  /// Buffer for key requests that arrive before the group key is stored locally.
  /// Maps chatUid -> list of pending request messages.
  static final Map<String, List<Message>> _pendingKeyRequests = {};

  /// Generate a secure group key in the same format as Kyber1024 baseKeys
  static String generateSecureGroupKey() {
    // Generate 32 random bytes (256 bits) for security - same as AES-256
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));

    // Encode as base64 to match the format of Kyber1024 baseKeys
    return base64Encode(bytes);
  }

  /// Create and distribute a group key (for group creators/admins)
  static Future<void> createAndDistributeGroupKey(String groupChatId) async {
    // Check if we already have a group key to avoid creating duplicates
    final existingKeys = await BaseKey.getKeys(groupChatId);
    if (existingKeys?.baseKey != null) {
      debugPrint(
          'GroupKeyExchange: [CREATOR] Already have group key for chat $groupChatId: ${existingKeys!.baseKey!.substring(0, 8)}... - skipping creation');
      return;
    }

    // Generate secure group key
    final groupKey = generateSecureGroupKey();

    // Store locally for creator
    await BaseKey.setKeys(
      chatUid: groupChatId,
      baseKey: groupKey,
      isInitiator: true,
    );

    debugPrint(
        'GroupKeyExchange: [CREATOR] Created and stored group key for chat $groupChatId: ${groupKey.substring(0, 8)}... (userId: ${Auth.user?.uid})');

    // Process any key requests that arrived before the key was stored
    await _processPendingKeyRequests(groupChatId);
  }

  /// Process any buffered key requests for a chat after the group key is stored
  static Future<void> _processPendingKeyRequests(String groupChatId) async {
    final pending = _pendingKeyRequests.remove(groupChatId);
    if (pending == null || pending.isEmpty) return;

    debugPrint(
        'GroupKeyExchange: Processing ${pending.length} buffered key request(s) for chat $groupChatId');
    for (final request in pending) {
      await handleGroupKeyRequest(request);
    }
  }

  /// Check if key exists, if not request it (called when chat opens)
  /// Works for both one-to-one and group chats using unified hybrid approach
  static Future<void> ensureGroupKey(String chatId, bool isOneToOne) async {
    // Check if we already have key
    final existingKeys = await BaseKey.getKeys(chatId);
    if (existingKeys?.baseKey != null) {
      // Already have key
      debugPrint(
          'GroupKeyExchange.ensureGroupKey: Already have key for chat $chatId: ${existingKeys!.baseKey!.substring(0, 8)}... (userId: ${Auth.user?.uid})');
      return;
    }

    // Don't have key - request it from other members
    debugPrint(
        'GroupKeyExchange.ensureGroupKey: No key found for chat $chatId - requesting from other members (userId: ${Auth.user?.uid})');
    final existingRequestKey = await BaseKey.getKeys('${chatId}_key_request');
    if (existingRequestKey?.private != null) {
      debugPrint(
          'GroupKeyExchange.ensureGroupKey: Already have request key for chat $chatId - skipping request');
      return;
    }
    requestGroupKey(chatId);
  }

  /// Request group key by sending a message with public key
  static Future<void> requestGroupKey(String groupChatId) async {
    // Generate Kyber key pair for this request
    final keyPair = await BaseKey.generateKeys();

    // Store my private key locally (keyed by group chat)
    await BaseKey.setKeys(
      chatUid: '${groupChatId}_key_request',
      private: keyPair.keyPair, // My private key
      isInitiator: true,
    );

    // Send message with my public key as the message text
    final requestMessage = Message(
      authorId: Auth.user?.uid ?? '',
      messageType: MessageTypes.requestForAGroupKey,
      text: keyPair.publicKey, // Alice's public key (ciphertext)
      createdAtMSE: DateTime.now().millisecondsSinceEpoch,
      chatUid: groupChatId,
      withBaseKey: false, // Can't encrypt since we don't have group key yet
    );

    await MessageService().sendGroupKeyRequest(requestMessage);
    debugPrint('GroupKeyExchange: Requested group key for chat $groupChatId');
  }

  /// Handle incoming group key request - respond if we have the group key
  static Future<void> handleGroupKeyRequest(Message requestMessage) async {
    final groupChatId = requestMessage.chatUid;
    final requesterPublicKey = requestMessage.text; // Alice's public key
    final requesterMessageId = requestMessage.uid;
    final requesterId = requestMessage.authorId;

    // Don't respond to our own requests
    if (requesterId == Auth.user?.uid) {
      return;
    }

    // Check if I have the group key to share
    final myKeys = await BaseKey.getKeys(groupChatId);
    if (myKeys?.baseKey == null) {
      // Don't have the key yet - buffer the request for later processing.
      // This handles the race condition where a key request arrives before
      // createAndDistributeGroupKey has finished storing the key.
      _pendingKeyRequests.putIfAbsent(groupChatId, () => []);
      _pendingKeyRequests[groupChatId]!.add(requestMessage);
      debugPrint(
          'GroupKeyExchange: No group key yet for chat $groupChatId - buffering request from $requesterId');
      return;
    }

    // I can help! Use Alice's public key to encrypt group key
    final encapResult = await BaseKey.encapsulate(requesterPublicKey!);
    if (encapResult == null) {
      debugPrint('GroupKeyExchange: Failed to encapsulate group key');
      return;
    }

    final encryptedGroupKey =
        await encodePayload(myKeys!.baseKey!, encapResult.sharedSecret, true);

    // Create response message: alice_message_id + bob_ciphertext + encrypted_group_key
    final responsePayload = json.encode({
      'requestMessageId': requesterMessageId,
      'ciphertext': encapResult.ciphertext, // Bob's ciphertext
      'encryptedGroupKey': encryptedGroupKey,
      'responderId': Auth.user?.uid,
    });

    // Send response message
    final responseMessage = Message(
      authorId: Auth.user?.uid ?? '',
      messageType: MessageTypes.responseForAGroupKey,
      text: responsePayload,
      createdAtMSE: DateTime.now().millisecondsSinceEpoch,
      chatUid: groupChatId,
      withBaseKey: false, // Response is structured data, not encrypted
    );

    await MessageService().sendGroupKeyRequest(responseMessage);
    debugPrint(
        'GroupKeyExchange: [RESPONDER] Sent group key response to $requesterId for chat $groupChatId: ${myKeys.baseKey!.substring(0, 8)}...');
  }

  /// Process group key response - extract and store group key if we requested it
  static Future<void> processGroupKeyResponse(Message responseMessage) async {
    try {
      debugPrint(
          'GroupKeyExchange: [RECEIVER] Processing group key response for chat ${responseMessage.text}');
      final responseData = json.decode(responseMessage.text ?? '');
      final bobCiphertext = responseData['ciphertext'];
      final encryptedGroupKey = responseData['encryptedGroupKey'];
      final responderId = responseData['responderId'];
      final groupChatId = responseMessage.chatUid;

      debugPrint(
          'GroupKeyExchange: [RECEIVER] Processing group key response for chat $groupChatId');
      debugPrint(
          'GroupKeyExchange: [RECEIVER] Response ciphertext: $bobCiphertext');
      debugPrint(
          'GroupKeyExchange: [RECEIVER] Response encrypted group key: $encryptedGroupKey');
      debugPrint(
          'GroupKeyExchange: [RECEIVER] Response responder id: $responderId');
      debugPrint(
          'GroupKeyExchange: [RECEIVER] Response group chat id: $groupChatId');

      // Check if we already have the group key (avoid duplicate processing)
      final existingKeys = await BaseKey.getKeys(groupChatId);
      if (existingKeys?.baseKey != null) {
        debugPrint(
            'GroupKeyExchange: Already have group key for chat $groupChatId - ignoring response from $responderId');
        return;
      }

      // Check if this response is for my request
      final myPrivateKey = await BaseKey.getKeys('${groupChatId}_key_request');
      if (myPrivateKey?.private == null) {
        // This response is not for me (I didn't request a key for this group)
        return;
      }

      // Decapsulate using my private key and Bob's ciphertext
      final sharedSecret =
          await BaseKey.decapsulate(myPrivateKey!.private!, bobCiphertext);

      if (sharedSecret != null) {
        // Decrypt the group key
        final groupKey = await decodePayload(encryptedGroupKey['crypted'],
            encryptedGroupKey['iv'], sharedSecret, true);

        // Store the group key!
        await BaseKey.setKeys(
          chatUid: groupChatId,
          baseKey: groupKey,
          isInitiator: false,
        );

        // Clean up request key
        await BaseKey.storage.delete(key: 'keys-${groupChatId}_key_request');

        debugPrint(
            'GroupKeyExchange: [RECEIVER] Successfully received group key from $responderId for chat $groupChatId: ${groupKey.substring(0, 8)}... (userId: ${Auth.user?.uid})');

        // Process any queued messages will be handled automatically by BaseKey.setKeys
      } else {
        debugPrint(
            'GroupKeyExchange: Failed to decapsulate group key from $responderId');
      }
    } catch (e) {
      debugPrint('GroupKeyExchange: Error processing response: $e');
    }
  }
}

/// Central message processor for handling all message types including group key exchange
class MessageProcessor {
  static Future<void> processMessage(Message message) async {
    switch (message.messageType) {
      case MessageTypes.requestForAGroupKey:
        // Someone is requesting group key
        await GroupKeyExchange.handleGroupKeyRequest(message);
        break;

      case MessageTypes.responseForAGroupKey:
        // Someone responded with group key
        await GroupKeyExchange.processGroupKeyResponse(message);
        break;

      case MessageTypes.text:
      case MessageTypes.audio:
      case MessageTypes.file:
      case MessageTypes.image:
        // Regular message processing - no special handling needed here
        // The existing message processing in SocketEventsService handles these
        break;

      default:
        // Unknown message type - ignore
        break;
    }
  }
}
