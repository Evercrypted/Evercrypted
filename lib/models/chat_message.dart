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
  final String? fileKey;
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
    this.fileKey,
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
        'withBaseKey': withBaseKey,
      };

  ChatMessage copyWith({
    String? baseKey,
    String? pass,
    String? iv,
    String? mac,
    String? error,
    int? decodedDuration,
    String? filePath,
    String? text,
    String? uid,
    int? queueId,
    String? chatUid,
    int? createdAtMSE,
    String? messageType,
    MessageStatus? messageStatus,
    bool? isSender,
    bool? isSystemMessage,
    EncryptionStatus? encryptionStatus,
    String? fileKey,
    bool? withBaseKey,
  }) =>
      ChatMessage(
        baseKey: baseKey ?? this.baseKey,
        pass: pass ?? this.pass,
        iv: iv ?? this.iv,
        mac: mac ?? this.mac,
        error: error ?? this.error,
        decodedDuration: decodedDuration ?? this.decodedDuration,
        filePath: filePath ?? this.filePath,
        text: text ?? this.text,
        uid: uid ?? this.uid,
        queueId: queueId ?? this.queueId,
        chatUid: chatUid ?? this.chatUid,
        createdAtMSE: createdAtMSE ?? this.createdAtMSE,
        messageType: messageType ?? this.messageType,
        messageStatus: messageStatus ?? this.messageStatus,
        isSender: isSender ?? this.isSender,
        isSystemMessage: isSystemMessage ?? this.isSystemMessage,
        encryptionStatus: encryptionStatus ?? this.encryptionStatus,
        fileKey: fileKey ?? this.fileKey,
        withBaseKey: withBaseKey ?? this.withBaseKey,
      );
}
