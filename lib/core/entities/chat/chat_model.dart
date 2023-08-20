import 'package:isar/isar.dart';

import '../profile/profile_model.dart';

part 'chat_model.g.dart';

@collection
class Chat {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String? uid;

  final int? messageLongevitySeconds;
  final String name;

  final List<String>? participants;

  final DateTime lastMessageTime;

  Avatar? avatar;

  Chat({
    this.uid,
    this.messageLongevitySeconds,
    required this.name,
    required this.participants,
    required this.lastMessageTime,
    this.avatar,
  });
}
