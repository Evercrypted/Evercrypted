import 'package:isar/isar.dart';

part 'message_isar.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  @Index()
  String? fbUid;

  String authorId;

  @Index()
  String? chatId;

  String? text;
  String? fileRef;

  @Index()
  int createdAtMSE;

  @ignore
  get createdAt {
    return DateTime.fromMillisecondsSinceEpoch(createdAtMSE);
  }

  Message({
    required this.authorId,
    required this.chatId,
    this.fbUid,
    this.text,
    this.fileRef,
    required this.createdAtMSE,
  });

  factory Message.fromJson(String uid, Map<String, dynamic> json) => Message(
      fbUid: uid,
      authorId: json['authorId'] as String,
      createdAtMSE: json['createdAtMSE'] as int,
      text: json['text'] as String?,
      fileRef: json['fileRef'] as String?,
      chatId: json['chatId'] as String?);

  Map<String, dynamic> toJson(Message instance) => <String, dynamic>{
        'fbUid': instance.fbUid,
        'authorId': instance.authorId,
        'createdAtMSE': instance.createdAtMSE,
        'text': instance.text,
        'fileRef': instance.fileRef,
      };
}
