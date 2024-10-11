import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:objectbox/objectbox.dart';

import '../profile/profile_model.dart';

@Entity()
class Chat {
  @Id()
  int id = 0;

  @Unique()
  final String uid;

  final int? messageLongevitySeconds;
  final String? name;

  final bool isOneToOne;

  @Backlink('chat')
  final participants = ToMany<Participant>();

  @Transient()
  List<Participant> participantsList;

  @Backlink('chat')
  final messages = ToMany<Message>();

  @Transient()
  List<Message> messagesList;

  @Index()
  @Property(type: PropertyType.date)
  DateTime? lastMessageTime;

  String? avatarColor;
  String? avatarIcon;
  String? avatarPic;

  bool? syncRequired;

  int? syncTime;

  Chat({
    this.isOneToOne = true,
    required this.uid,
    this.messageLongevitySeconds,
    this.name,
    required this.lastMessageTime,
    this.participantsList = const [],
    this.messagesList = const [],
    this.avatarColor,
    this.avatarIcon,
    this.avatarPic,
    this.syncRequired,
    this.syncTime,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        uid: json['uid'] as String,
        messageLongevitySeconds: json['messageLongevitySeconds'] as int?,
        name: json['name'] as String?,
        participantsList: (json['participants'] as List<dynamic>)
            .map((e) => Participant.fromJson(e))
            .toList(),
        messagesList: (json['messages'] as List<dynamic>)
            .map((e) => Message.fromJson(e))
            .toList(),
        lastMessageTime: DateTime.parse(json['lastMessageTime']),
        avatarColor: Avatar.fromJson(
          json['avatar'],
        ).color,
        avatarIcon: Avatar.fromJson(
          json['avatar'],
        ).icon,
        avatarPic: Avatar.fromJson(
          json['avatar'],
        ).pic,
        isOneToOne: json['isOneToOne'] as bool,
        syncRequired: json['syncRequired'] as bool? ?? false,
        syncTime: json['syncTime'] as int?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'name': name,
        'messageLongevitySeconds': messageLongevitySeconds,
        'participants': participantsList,
        'lastMessageTime': lastMessageTime,
        'avatar': Avatar(color: avatarColor, icon: avatarIcon, pic: avatarPic)
            .toJson(),
        'isOneToOne': isOneToOne,
      };
}

class NewOneToOneChatDTO {
  String contact;
  String? pubKey;

  NewOneToOneChatDTO({required this.contact, this.pubKey});

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'contact': contact, 'pubKey': pubKey};
}

class NewGroupChatDTO {
  String? name;
  List<Participant> participants;
  Avatar? avatar;

  NewGroupChatDTO({this.name, required this.participants, this.avatar});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'participants':
            participants.map((participant) => participant.toJson()).toList(),
        'avatar': avatar?.toJson(),
      };

  copyWith({String? name, List<Participant>? participants, Avatar? avatar}) =>
      NewGroupChatDTO(
        name: name ?? this.name,
        participants: participants ?? this.participants,
        avatar: avatar ?? this.avatar,
      );
}
