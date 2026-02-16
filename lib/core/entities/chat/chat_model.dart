import 'dart:convert';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/db_encryption.dart';
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

  @Transient()
  List<Participant> participants;

  @Transient()
  List<InviteLink> inviteLinks;

  @Backlink('chat')
  final ToMany<Message> messages = ToMany<Message>();

  @Transient()
  List<Message> messagesList;

  @Index()
  @Property(type: PropertyType.date)
  DateTime? lastMessageTime;

  @Transient()
  Avatar? avatar;

  String? get dbInviteLinks => inviteLinks.isEmpty
      ? null
      : jsonEncode(inviteLinks.map((e) => e.toJson()).toList());

  set dbInviteLinks(String? value) {
    if (value == null) {
      inviteLinks = [];
    } else {
      inviteLinks = (jsonDecode(value) as List<dynamic>)
          .map((e) => InviteLink.fromJson(e))
          .toList();
    }
  }

  String? get dbAvatar => avatar == null ? null : jsonEncode(avatar?.toJson());

  set dbAvatar(String? value) {
    if (value == null) {
      avatar = null;
    } else {
      avatar = Avatar.fromJson(jsonDecode(value));
    }
  }

  String? get dbParticipants => jsonEncode(participants.map((e) {
        final String? appKey = Auth.appKey;
        if (appKey == null) {
          return e.toJson(lastSawChatInMiliseconds: true);
        } else {
          return e
              .copyWith(
                  email: encryptForDb(e.email, appKey),
                  name: encryptForDb(e.name, appKey))
              .toJson(lastSawChatInMiliseconds: true);
        }
      }).toList());

  set dbParticipants(String? value) {
    if (value == null) {
      participants = [];
    } else {
      final String? appKey = Auth.appKey;
      if (appKey == null) {
        participants = (jsonDecode(value) as List<dynamic>)
            .map((e) => Participant.fromJson(e, lastSawChatInMiliseconds: true))
            .toList();
      } else {
        participants = (jsonDecode(value) as List<dynamic>).map((e) {
          return Participant.fromJson(e, lastSawChatInMiliseconds: true)
              .copyWith(
            email: decryptForDb(e['email'], appKey),
            name: decryptForDb(e['name'], appKey),
          );
        }).toList();
      }
    }
  }

  Chat({
    this.isOneToOne = true,
    required this.uid,
    this.messageLongevitySeconds,
    this.name,
    required this.lastMessageTime,
    this.participants = const [],
    this.messagesList = const [],
    this.avatar,
    this.inviteLinks = const [],
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        uid: json['uid'] as String,
        messageLongevitySeconds: json['messageLongevitySeconds'] as int?,
        name: json['name'] as String?,
        participants: (json['participants'] as List<dynamic>)
            .map((e) => Participant.fromJson(e))
            .toList(),
        messagesList: (json['messages'] as List<dynamic>? ?? [])
            .map((e) => Message.fromJson(e))
            .toList(),
        lastMessageTime: DateTime.parse(json['lastMessageTime']),
        avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
        isOneToOne: json['isOneToOne'] as bool,
        inviteLinks: (json['inviteLinks'] as List<dynamic>? ?? [])
            .map((e) => InviteLink.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'name': name,
        'messageLongevitySeconds': messageLongevitySeconds,
        'participants': participants,
        'lastMessageTime': lastMessageTime,
        'avatar': avatar?.toJson(),
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

class InviteLink {
  final String token;
  final String type; // 'permanent' or 'one_time'
  final DateTime createdAt;

  InviteLink({
    required this.token,
    required this.type,
    required this.createdAt,
  });

  bool get isPermanent => type == 'permanent';
  bool get isOneTime => type == 'one_time';

  factory InviteLink.fromJson(Map<String, dynamic> json) => InviteLink(
        token: json['token'] as String,
        type: json['type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'token': token,
        'type': type,
        'created_at': createdAt.toIso8601String(),
      };
}
