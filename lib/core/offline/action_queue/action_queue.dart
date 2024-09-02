import 'package:isar/isar.dart';

part 'action_queue.g.dart';

@collection
class ActionQueue {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  @Index()
  String channel;

  @Index()
  String type;

  String payload;

  @Index()
  int createdAtMSE;

  @Index()
  bool isHttp;

  @ignore
  get createdAt {
    return DateTime.fromMillisecondsSinceEpoch(createdAtMSE);
  }

  ActionQueue({
    this.isHttp = false,
    required this.type,
    required this.channel,
    required this.payload,
    required this.createdAtMSE,
  });
}
