import 'package:isar/isar.dart';

part 'message_isar.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;

  //needs composite unique index with chatUId
  @Index()
  String? uid;

  String authorEmail;

  String? text;
  List<String>? fileIds;

  @Index()
  int timestamp;

  int messageType;

  @ignore
  get createdAt {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Message({
    this.uid,
    required this.authorEmail,
    this.text,
    this.fileIds,
    required this.timestamp,
    required this.messageType,
  });
}

class MessageTypes {
  MessageTypes._();
  static const v1 = 1;
}
