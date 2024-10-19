enum MessageStatus { successfullySent, queued, couldNotSend }

enum EncryptionStatus { encrypted, notEncrypted, decrypted, failed }

class ChatMessage {
  final String? text;
  String? decrypted;
  final String messageType;
  MessageStatus messageStatus;
  final bool isSender;
  String? pass;
  final String? baseKey;
  final String? iv;
  final String? mac;
  final String? error;
  final String? filePath;
  final String? duration;
  final String? durationIV;
  final String? durationMAC;
  final String? uid;
  final String chatUid;
  final int? queueId;
  int? decodedDuration;
  final bool isSystemMessage;
  final int createdAtMSE;
  final bool withBaseKey;
  EncryptionStatus encryptionStatus;

  ChatMessage({
    this.baseKey,
    this.pass,
    this.iv,
    this.mac,
    this.error,
    this.duration,
    this.durationIV,
    this.durationMAC,
    this.decodedDuration,
    this.filePath,
    this.text = '',
    this.uid,
    this.queueId,
    this.withBaseKey = false,
    required this.chatUid,
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
        'error': error,
        'isSystemMessage': isSystemMessage,
        'createdAtMSE': createdAtMSE,
        'duration': duration,
        'withBaseKey': withBaseKey,
      };
}
