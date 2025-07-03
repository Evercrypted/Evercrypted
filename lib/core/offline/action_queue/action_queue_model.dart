import 'package:objectbox/objectbox.dart';

@Entity()
class ActionQueue {
  @Id()
  int id = 0; // you can also use id = null to auto increment

  @Index()
  String channel;

  @Index()
  String type;

  String payload;

  @Index()
  int createdAtMSE;

  @Transient()
  get createdAt {
    return DateTime.fromMillisecondsSinceEpoch(createdAtMSE);
  }

  ActionQueue({
    required this.type,
    required this.channel,
    required this.payload,
    required this.createdAtMSE,
  });
}
