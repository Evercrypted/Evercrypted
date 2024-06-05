enum MessageStatus { successfullySent, queued, couldNotSend }

enum EncryptionStatus { encrypted, notEncrypted }

class ChatMessage {
  final String text;
  final String messageType;
  final MessageStatus messageStatus;
  final bool isSender;

  ChatMessage({
    this.text = '',
    required this.messageType,
    required this.messageStatus,
    required this.isSender,
  });
}
