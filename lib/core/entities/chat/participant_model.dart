import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Participant {
  @Id()
  int id = 0;

  @Unique()
  final String? uid;

  @Unique()
  final String? email;
  final String? name;

  @Property(type: PropertyType.date)
  final DateTime? lastSawChat;

  final bool isCreator;
  final bool isAdmin;
  final String? pubKey;
  final bool gotPubKey;

  final String? avatarColor;
  final String? avatarIcon;
  final String? avatarPic;

  @Index()
  final chat = ToOne<Chat>();

  Participant({
    this.uid,
    this.email,
    this.name,
    this.lastSawChat,
    this.avatarColor,
    this.avatarIcon,
    this.avatarPic,
    this.isCreator = false,
    this.isAdmin = false,
    this.pubKey,
    this.gotPubKey = false,
  });

  factory Participant.fromContact(Contact contact) => Participant(
      uid: contact.contactPersonUid,
      email: contact.email,
      name: contact.name,
      avatarColor: contact.avatarColor,
      avatarIcon: contact.avatarIcon,
      avatarPic: contact.avatarPic);

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        uid: json['uid'] as String?,
        email: json['email'] as String?,
        name: json['name'] as String?,
        lastSawChat: json['last_saw_chat'] != null
            ? DateTime.parse(json['last_saw_chat'])
            : null,
        avatarColor: Avatar.fromJson(
          json['avatar'],
        ).color,
        avatarIcon: Avatar.fromJson(
          json['avatar'],
        ).icon,
        avatarPic: Avatar.fromJson(
          json['avatar'],
        ).pic,
        isCreator: json['is_creator'] as bool? ?? false,
        isAdmin: json['is_admin'] as bool? ?? false,
        pubKey: json['pub_key'] as String?,
        gotPubKey: json['got_pub_key'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'email': email,
        'name': name,
        'last_saw_chat': lastSawChat,
        'avatar': Avatar(color: avatarColor, icon: avatarIcon, pic: avatarPic)
            .toJson(),
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
    String? avatarColor,
    String? avatarIcon,
    String? avatarPic,
  }) =>
      Participant(
          uid: uid ?? this.uid,
          email: email ?? this.email,
          name: name ?? this.name,
          lastSawChat: lastSawChat ?? this.lastSawChat,
          avatarColor: avatarColor ?? this.avatarColor,
          avatarIcon: avatarIcon ?? this.avatarIcon,
          avatarPic: avatarPic ?? this.avatarPic,
          isCreator: isCreator ?? this.isCreator,
          isAdmin: isAdmin ?? this.isAdmin,
          pubKey: pubKey ?? this.pubKey,
          gotPubKey: gotPubKey ?? this.gotPubKey);
}
