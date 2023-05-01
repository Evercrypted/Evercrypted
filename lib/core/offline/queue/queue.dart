import 'package:isar/isar.dart';

@collection
class Queue {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  @Index()
  String type;

  String payload;

  @Index()
  String channel;

  String? text;
  String? fileRef;

  @Index()
  int createdAtMSE;

  @ignore
  get createdAt {
    return DateTime.fromMillisecondsSinceEpoch(createdAtMSE);
  }

  Queue({
    required this.type,
    required this.channel,
    required this.payload,
    this.text,
    this.fileRef,
    required this.createdAtMSE,
  });
}
