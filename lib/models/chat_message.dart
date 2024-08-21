enum MessageStatus { successfullySent, queued, couldNotSend }

enum EncryptionStatus { encrypted, notEncrypted, decrypted, failed }

class ChatMessage {
  final String text;
  String? decrypted;
  final String messageType;
  MessageStatus messageStatus;
  final bool isSender;
  String? pass;
  final String? baseKey;
  final String? iv;
  final String? mac;
  final bool isSystemMessage;
  final int createdAtMSE;
  EncryptionStatus encryptionStatus;

  ChatMessage({
    this.baseKey,
    this.pass,
    this.iv,
    this.mac,
    this.text = '',
    required this.createdAtMSE,
    required this.messageType,
    required this.messageStatus,
    required this.isSender,
    required this.isSystemMessage,
    this.encryptionStatus = EncryptionStatus.notEncrypted,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'text': text,
        'messageType': messageType,
        'messageStatus': messageStatus.toString(),
        'isSender': isSender,
        'pass': pass,
        'iv': iv,
        'mac': mac,
        'encryptionStatus': encryptionStatus.toString(),
      };
}
