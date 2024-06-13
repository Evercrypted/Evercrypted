enum MessageStatus { successfullySent, queued, couldNotSend }

enum EncryptionStatus { encrypted, notEncrypted, decrypted, failed }

class ChatMessage {
  String text;
  final String messageType;
  MessageStatus messageStatus;
  final bool isSender;
  String? pass;
  final String? iv;
  final String? mac;
  EncryptionStatus encryptionStatus;

  ChatMessage({
    this.pass,
    this.iv,
    this.mac,
    this.text = '',
    required this.messageType,
    required this.messageStatus,
    required this.isSender,
    this.encryptionStatus = EncryptionStatus.notEncrypted,
  });
}
