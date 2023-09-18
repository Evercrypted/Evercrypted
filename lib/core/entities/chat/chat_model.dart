import 'package:isar/isar.dart';

import '../profile/profile_model.dart';

part 'chat_model.g.dart';

@collection
class Chat {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String? uid;

  final int? messageLongevitySeconds;
  final String? name;

  final List<String>? participants;

  final DateTime? lastMessageTime;

  Avatar? avatar;

  Chat({
    this.uid,
    this.messageLongevitySeconds,
    required this.name,
    required this.participants,
    required this.lastMessageTime,
    this.avatar,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        uid: json['uid'] as String?,
        messageLongevitySeconds: json['messageLongevitySeconds'] as int?,
        name: json['name'] as String?,
        participants: json['participants'] as List<String>?,
        lastMessageTime: json['lastMessageTime'] as DateTime?,
        avatar: Avatar.fromJson(
          json['avatar'],
        ),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'messageLongevitySeconds': messageLongevitySeconds,
        'participants': participants,
        'lastMessageTime': lastMessageTime,
        'avatar': avatar?.toJson(),
      };
}

class NewChatDTO {
  String? name;
  List<String> participants;
  Avatar? avatar;

  NewChatDTO({
    this.name,
    required this.participants,
    this.avatar,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'participants': participants,
        'avatar': avatar?.toJson(),
      };
}
