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

  final List<Participant> participants;

  @Index()
  final DateTime? lastMessageTime;

  Avatar? avatar;

  Chat({
    this.uid,
    this.messageLongevitySeconds,
    this.name,
    required this.participants,
    required this.lastMessageTime,
    this.avatar,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        uid: json['uid'] as String?,
        messageLongevitySeconds: json['messageLongevitySeconds'] as int?,
        name: json['name'] as String?,
        participants: (json['participants'] as List<dynamic>)
            .map((e) => Participant.fromJson(e))
            .toList(),
        lastMessageTime: DateTime.parse(json['lastMessageTime']),
        avatar: json['avatar'] != null
            ? Avatar.fromJson(
                json['avatar'],
              )
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'name': name,
        'messageLongevitySeconds': messageLongevitySeconds,
        'participants': participants,
        'lastMessageTime': lastMessageTime,
        'avatar': avatar?.toJson(),
      };
}

@embedded
class Participant {
  final String? uid;
  final String? email;
  final String? name;
  final DateTime? lastSawChat;
  final Avatar? avatar;

  Participant({this.uid, this.email, this.name, this.lastSawChat, this.avatar});

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        uid: json['uid'] as String?,
        email: json['email'] as String?,
        name: json['name'] as String?,
        lastSawChat: json['lastSawChat'] as DateTime?,
        avatar: json['avatar'] != null
            ? Avatar.fromJson(
                json['avatar'],
              )
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'email': email,
        'name': name,
        'lastSawChat': lastSawChat,
        'avatar': avatar?.toJson(),
      };
}

class NewChatDTO {
  String contact;

  NewChatDTO({required this.contact});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'contact': contact,
      };
}
