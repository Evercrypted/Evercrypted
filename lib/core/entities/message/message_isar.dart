import 'package:isar/isar.dart';

part 'message_isar.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  String authorId;

  String? text;
  String? fileRef;

  int createdAtMSE;

  Message({
    required this.authorId,
    this.text,
    this.fileRef,
    required this.createdAtMSE,
  });
}
