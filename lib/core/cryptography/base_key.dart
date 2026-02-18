import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/cryptography/voice_message.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_model.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/objectbox.g.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_ever_crypto/flutter_ever_crypto.dart';
import 'package:rxdart/rxdart.dart';

class ChatKeys {
  final String chatUid;
  final String? baseKey;
  final String? private;
  final String? ciphertext; // For storing encapsulated data
  final bool? isInitiator; // Track if this device initiated the chat

  ChatKeys({
    required this.chatUid,
    this.baseKey,
    this.private,
    this.ciphertext,
    this.isInitiator,
  });

  ChatKeys.fromJson(Map<String, dynamic> json)
      : chatUid = json['chatUid'],
        baseKey = json['baseKey'],
        private = json['private'],
        ciphertext = json['ciphertext'],
        isInitiator = json['isInitiator'];
  // Note: pubCombo field is ignored for backward compatibility

  Map<String, dynamic> toJson() {
    return {
      'chatUid': chatUid,
      'baseKey': baseKey,
      'private': private,
      'ciphertext': ciphertext,
      'isInitiator': isInitiator,
    };
  }
}

class BaseKey {
  BaseKey._();

  static BehaviorSubject<String> baseKeySubject = BehaviorSubject<String>();

  static const storage = FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      aOptions: AndroidOptions());

  static Future<Base64KeyData> generateKeys() async {
    final keyPair = EverCrypto.generateKyberKeyPair();
    final base64KeyPair = base64Encode(keyPair.secretKey);
    final base64PublicKey = base64Encode(keyPair.publicKey);
    return Base64KeyData(keyPair: base64KeyPair, publicKey: base64PublicKey);
  }

  // Decapsulate shared secret using private key (for key recipient)
  static Future<String?> decapsulate(
      String secretKeyBytesBase64, String ciphertextBytesBase64) async {
    try {
      final secretKey = base64Decode(secretKeyBytesBase64);
      final ciphertext = base64Decode(ciphertextBytesBase64);

      // Decapsulate the shared secret using Kyber1024
      final sharedSecret = EverCrypto.kyberDecapsulate(ciphertext, secretKey);

      return base64Encode(sharedSecret);
    } catch (e) {
      return null;
    }
  }

  // Encapsulate shared secret using public key (for key sender)
  static Future<EncapsulationResult?> encapsulate(
      String publicKeyBytesBase64) async {
    try {
      final publicKey = base64Decode(publicKeyBytesBase64);

      // Encapsulate to generate shared secret and ciphertext
      final result = EverCrypto.kyberEncapsulate(publicKey);

      return EncapsulationResult(
        sharedSecret: base64Encode(result.sharedSecret),
        ciphertext: base64Encode(result.ciphertext),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<ChatKeys> setKeys({
    required String chatUid,
    String? baseKey,
    String? private,
    String? ciphertext,
    bool? isInitiator,
  }) async {
    ChatKeys? current = await getKeys(chatUid);
    late ChatKeys keys;
    if (current != null) {
      keys = ChatKeys(
        chatUid: chatUid,
        baseKey: baseKey ?? current.baseKey,
        private: private ?? current.private,
        ciphertext: ciphertext ?? current.ciphertext,
        isInitiator: isInitiator ?? current.isInitiator,
      );
    } else {
      keys = ChatKeys(
        chatUid: chatUid,
        baseKey: baseKey,
        private: private,
        ciphertext: ciphertext,
        isInitiator: isInitiator,
      );
    }
    await storage.write(key: 'keys-$chatUid', value: jsonEncode(keys.toJson()));
    if (baseKey != null) {
      baseKeySubject.add(chatUid);
      // Process any queued messages waiting for this base key
      await _processQueuedMessages(chatUid);
    }
    return keys;
  }

  static Future<ChatKeys?> getKeys(String chatUid) async {
    final String? string = await storage.read(key: 'keys-$chatUid');
    return string != null ? ChatKeys.fromJson(jsonDecode(string)) : null;
  }

  /// Process pending messages for all chats that have baseKeys
  /// Call this on app startup or socket reconnect to handle messages queued before key exchange
  static Future<void> processAllPendingMessages() async {
    // Find all queued messages waiting for key exchange
    final query = ObxInit.obx.actionQueues
        .query(ActionQueue_.type.equals('sendMessagePendingKey'))
        .build();
    final queuedActions = query.find();
    query.close();

    if (queuedActions.isEmpty) {
      return;
    }

    // Group by chatUid
    final Map<String, List<ActionQueue>> messagesByChat = {};
    for (final action in queuedActions) {
      final payload = jsonDecode(action.payload);
      final chatUid = payload['chatUid'] as String?;
      if (chatUid != null) {
        messagesByChat.putIfAbsent(chatUid, () => []).add(action);
      }
    }

    // Process each chat's pending messages (pass actions to avoid re-querying)
    for (final entry in messagesByChat.entries) {
      await _processQueuedMessagesForChat(entry.key, entry.value);
    }
  }

  /// Process pending messages for a specific chat (internal helper with pre-filtered actions)
  static Future<void> _processQueuedMessagesForChat(
      String chatUid, List<ActionQueue> actions) async {
    final messageService = MessageService();

    for (final action in actions) {
      final payload = jsonDecode(action.payload);
      // Double-check chatUid matches
      if (payload['chatUid'] == chatUid) {
        // Get the base key that's now available
        final keys = await getKeys(chatUid);
        if (keys?.baseKey != null) {
          // Create the encryption key (same logic as ChatInputField)
          final hash = sha256.convert(utf8.encode(keys!.baseKey!));
          final encryptionKey = base64Encode(hash.bytes);

          final messageType = payload['messageType'] ?? MessageTypes.text;

          if (messageType == MessageTypes.text) {
            // Handle text message
            final encryptedMessage =
                await encodePayload(payload['text'], encryptionKey, true);

            // Send the encrypted message, updating the existing optimistic message
            await messageService.sendMessage(
              encryptedMessage,
              chatUid,
              true, // withBaseKey = true
              queueId: action
                  .id, // Update optimistic message instead of creating new one
            );
          } else if (messageType == MessageTypes.audio) {
            // Handle audio message with combined format (recording + duration + decibels)
            if (payload['fileData'] == null) {
              ObxInit.obx.actionQueues.remove(action.id);
              continue;
            }

            final fileData = base64Decode(payload['fileData']);
            final duration = payload['duration'];
            final waveData = payload['waveData'] != null
                ? List<double>.from(payload['waveData'])
                : <double>[];

            // Create combined payload using the new format
            final recordingPayload = createRecordingPayload(
              fileData,
              duration,
              waveData,
            );

            // Encrypt the combined payload
            final encrypted =
                await encodePayload(recordingPayload, encryptionKey, true);

            if (encrypted != null) {
              final messageToSend = Message(
                authorId: Auth.user?.uid ?? '',
                messageType: MessageTypes.audio,
                iv: encrypted['iv'],
                isEncrypted: true,
                createdAtMSE: DateTime.now().millisecondsSinceEpoch,
                chatUid: chatUid,
                withBaseKey: true,
              );

              await messageService.sendFile(
                  message: messageToSend,
                  file: encrypted['crypted'],
                  optimisticMessageQueueId:
                      action.id); // Update optimistic message
            }
          } else if (messageType == MessageTypes.file ||
              messageType == MessageTypes.image) {
            // Handle file/image message
            if (payload['fileData'] == null || payload['fileName'] == null) {
              ObxInit.obx.actionQueues.remove(action.id);
              continue;
            }

            final fileData = base64Decode(payload['fileData']);
            final fileName = payload['fileName'];

            final encryptedFile = await encodePayload({
              'name': fileName,
              'bytes': fileData,
            }, encryptionKey, true);

            final messageToSend = Message(
              authorId: Auth.user?.uid ?? '',
              messageType: messageType,
              iv: encryptedFile['iv'],
              mac: encryptedFile['mac'],
              isEncrypted: true,
              createdAtMSE: DateTime.now().millisecondsSinceEpoch,
              chatUid: chatUid,
              withBaseKey: true,
            );

            await messageService.sendFile(
                message: messageToSend,
                file: encryptedFile['crypted'],
                optimisticMessageQueueId:
                    action.id); // Update optimistic message
          }

          // Remove from queue
          ObxInit.obx.actionQueues.remove(action.id);
        }
      }
    }
  }

  /// Process pending messages when a specific chat's key becomes available
  /// This is the original method called from setKeys
  static Future<void> _processQueuedMessages(String chatUid) async {
    // Find all queued messages for this chat
    final query = ObxInit.obx.actionQueues
        .query(ActionQueue_.type.equals('sendMessagePendingKey'))
        .build();
    final queuedActions = query.find();
    query.close();

    // Filter to this chat and process
    final chatActions = queuedActions.where((action) {
      try {
        final payload = jsonDecode(action.payload);
        return payload['chatUid'] == chatUid;
      } catch (e) {
        return false;
      }
    }).toList();

    if (chatActions.isNotEmpty) {
      await _processQueuedMessagesForChat(chatUid, chatActions);
    }
  }
}

class Base64KeyData {
  String keyPair;
  String publicKey;

  Base64KeyData({required this.keyPair, required this.publicKey});
}

class EncapsulationResult {
  String sharedSecret;
  String ciphertext;

  EncapsulationResult({required this.sharedSecret, required this.ciphertext});
}
