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

  @Index(unique: true)
  String? chatUid;

  Message({
    this.uid,
    required this.authorId,
    this.text,
    this.fileIds,
    required this.createdAtMSE,
    this.iv,
    this.isEncrypted = false,
  });
}
