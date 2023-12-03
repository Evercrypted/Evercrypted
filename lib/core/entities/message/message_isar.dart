import 'package:isar/isar.dart';

part 'message_isar.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;

  //needs composite unique index with chatUId
  @Index()
  String? uid;

  String authorId;

  String? text;
  String? iv;
  String? mac;
  bool isEncrypted;

  List<String>? fileIds;

  @Index()
  int createdAtMSE;

  @Index()
  String chatUid;

  Message({
    this.uid,
    required this.authorId,
    this.text,
    this.fileIds,
    required this.createdAtMSE,
    this.iv,
    this.mac,
    this.isEncrypted = false,
    required this.chatUid,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        uid: json['uid'] as String,
        authorId: json['authorId'] as String,
        text: json['text'] as String?,
        fileIds:
            (json['fileIds'] as List<dynamic>).map((e) => e as String).toList(),
        createdAtMSE: json['createdAt'] as int,
        chatUid: json['chatUid'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'authorId': authorId,
        'text': text,
        'fileIds': fileIds,
        'createdAt': createdAtMSE,
        'chatUid': chatUid,
        'isEncrypted': isEncrypted,
        'iv': iv,
        'mac': mac,
      };
}
