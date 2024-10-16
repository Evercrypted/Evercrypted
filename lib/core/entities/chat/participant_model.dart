import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';

class Participant {
  final String? uid;
  final String? email;
  final String? name;
  final DateTime? lastSawChat;
  final bool isCreator;
  final bool isAdmin;
  final String? pubKey;
  final bool gotPubKey;

  final Avatar? avatar;

  Participant({
    this.uid,
    this.email,
    this.name,
    this.lastSawChat,
    this.avatar,
    this.isCreator = false,
    this.isAdmin = false,
    this.pubKey,
    this.gotPubKey = false,
  });

  factory Participant.fromContact(Contact contact) => Participant(
        uid: contact.contactPersonUid,
        email: contact.email,
        name: contact.name,
        avatar: contact.avatar,
      );

  factory Participant.fromJson(Map<String, dynamic> json,
          {lastSawChatInMiliseconds = false}) =>
      Participant(
        uid: json['uid'] as String?,
        email: json['email'] as String?,
        name: json['name'] as String?,
        lastSawChat: json['last_saw_chat'] != null
            ? lastSawChatInMiliseconds
                ? DateTime.fromMillisecondsSinceEpoch(json['last_saw_chat'])
                : DateTime.parse(json['last_saw_chat'])
            : null,
        avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
        isCreator: json['is_creator'] as bool? ?? false,
        isAdmin: json['is_admin'] as bool? ?? false,
        pubKey: json['pub_key'] as String?,
        gotPubKey: json['got_pub_key'] as bool? ?? false,
      );

  Map<String, dynamic> toJson({lastSawChatInMiliseconds = false}) =>
      <String, dynamic>{
        'uid': uid,
        'email': email,
        'name': name,
        'last_saw_chat': lastSawChatInMiliseconds
            ? lastSawChat?.millisecondsSinceEpoch
            : lastSawChat,
        'avatar': avatar?.toJson(),
        'is_creator': isCreator,
        'is_admin': isAdmin,
        'pub_key': pubKey,
        'got_pub_key': gotPubKey,
      };

  Participant copyWith({
    String? uid,
    String? email,
    String? name,
    DateTime? lastSawChat,
    bool? isCreator,
    bool? isAdmin,
    String? pubKey,
    bool? gotPubKey,
    Avatar? avatar,
  }) =>
      Participant(
          uid: uid ?? this.uid,
          email: email ?? this.email,
          name: name ?? this.name,
          lastSawChat: lastSawChat ?? this.lastSawChat,
          avatar: avatar ?? this.avatar,
          isCreator: isCreator ?? this.isCreator,
          isAdmin: isAdmin ?? this.isAdmin,
          pubKey: pubKey ?? this.pubKey,
          gotPubKey: gotPubKey ?? this.gotPubKey);
}
