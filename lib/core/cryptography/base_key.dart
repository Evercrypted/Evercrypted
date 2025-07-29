import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/payload.dart';
import 'package:evercrypted/core/cryptography/voice_message.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:flutter/foundation.dart';
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

  static Future<void> _processQueuedMessages(String chatUid) async {
    try {
      // Find all queued messages for this chat that are waiting for key exchange
      final query = obx.actionQueues
          .query(ActionQueue_.type.equals('sendMessagePendingKey'))
          .build();
      final queuedActions = query.find();
      query.close();

      final messageService = MessageService();
      int processedCount = 0;

      for (final action in queuedActions) {
        try {
          final payload = jsonDecode(action.payload);
          if (payload['chatUid'] == chatUid) {
            // Get the base key that's now available
            final keys = await getKeys(chatUid);
            if (keys?.baseKey != null) {
              // Create the encryption key (same logic as ChatInputField)
              final hash = sha256.convert(utf8.encode(keys!.baseKey!));
              final encryptionKey = base64Encode(hash.bytes);
              
              debugPrint('BaseKey._processQueuedMessages: Processing queued messages for chat $chatUid');
              debugPrint('BaseKey._processQueuedMessages: baseKey: ${keys!.baseKey!.substring(0, 8)}...');
              debugPrint('BaseKey._processQueuedMessages: encryptionKey: ${encryptionKey.substring(0, 8)}... (userId: ${Auth.user?.uid})');

              final messageType = payload['messageType'] ?? MessageTypes.text;

              if (messageType == MessageTypes.text) {
                // Handle text message
                final encryptedMessage =
                    await encodePayload(payload['text'], encryptionKey, true);

                // Send the encrypted message
                await messageService.sendMessage(
                  encryptedMessage,
                  chatUid,
                  true, // withBaseKey = true
                );
              } else if (messageType == MessageTypes.audio) {
                // Handle audio message
                final fileData = base64Decode(payload['fileData']);
                final duration = payload['duration'];

                final encryptedRecording =
                    await encodeRecording(encryptionKey, fileData);
                final encryptedDuration =
                    await encodePayload(duration, encryptionKey, true);

                if (encryptedRecording != null && encryptedDuration != null) {
                  final messageToSend = Message(
                    authorId: Auth.user?.uid ?? '',
                    messageType: MessageTypes.audio,
                    iv: encryptedRecording.iv,
                    mac: encryptedRecording.mac,
                    isEncrypted: true,
                    playbackDurationMicroSeconds: encryptedDuration['crypted'],
                    durationIV: encryptedDuration['iv'],
                    durationMAC: encryptedDuration['mac'],
                    createdAtMSE: DateTime.now().millisecondsSinceEpoch,
                    chatUid: chatUid,
                    withBaseKey: true,
                  );

                  await messageService.sendFile(
                      message: messageToSend,
                      file: encryptedRecording.cryptedRecording);
                }
              } else if (messageType == MessageTypes.file ||
                  messageType == MessageTypes.image) {
                // Handle file/image message
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
                    message: messageToSend, file: encryptedFile['crypted']);
              }

              // Remove from queue
              obx.actionQueues.remove(action.id);
              processedCount++;
            }
          }
        } catch (e) {
          debugPrint(
              'BaseKey: Error processing queued message ${action.id}: $e');
        }
      }

      if (processedCount > 0) {
        debugPrint(
            'BaseKey: Processed $processedCount queued messages for chat $chatUid');
      }
    } catch (e) {
      debugPrint(
          'BaseKey: Error processing queued messages for chat $chatUid: $e');
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
