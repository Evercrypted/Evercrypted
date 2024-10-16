import 'dart:convert';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
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

  @Backlink('chat')
  final ToMany<Message> messages = ToMany<Message>();

  @Transient()
  List<Message> messagesList;

  @Index()
  @Property(type: PropertyType.date)
  DateTime? lastMessageTime;

  @Transient()
  Avatar? avatar;

  bool? syncRequired;

  int? syncTime;

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
                  email: fernetEncrypt(e.email, appKey),
                  name: fernetEncrypt(e.name, appKey))
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
            email: fernetDecrypt(e['email'], appKey),
            name: fernetDecrypt(e['name'], appKey),
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
    this.syncRequired,
    this.syncTime,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        uid: json['uid'] as String,
        messageLongevitySeconds: json['messageLongevitySeconds'] as int?,
        name: json['name'] as String?,
        participants: (json['participants'] as List<dynamic>)
            .map((e) => Participant.fromJson(e))
            .toList(),
        messagesList: (json['messages'] as List<dynamic>)
            .map((e) => Message.fromJson(e))
            .toList(),
        lastMessageTime: DateTime.parse(json['lastMessageTime']),
        avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
        isOneToOne: json['isOneToOne'] as bool,
        syncRequired: json['syncRequired'] as bool? ?? false,
        syncTime: json['syncTime'] as int?,
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
