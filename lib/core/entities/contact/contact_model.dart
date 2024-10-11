import 'package:objectbox/objectbox.dart';

import '../profile/profile_model.dart';

@Entity()
class Contact {
  @Id()
  int id = 0;

  @Unique()
  final String? uid;

  final String? email;

  @Unique()
  final String? contactPersonUid;

  String? avatarColor;
  String? avatarIcon;
  String? avatarPic;

  String? name;

  bool isFavorite;

  Contact(
      {this.uid,
      this.email,
      this.avatarColor,
      this.avatarIcon,
      this.avatarPic,
      this.name,
      this.contactPersonUid,
      this.isFavorite = false});

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        uid: json['uid'] as String?,
        email: json['email'] as String?,
        avatarColor: Avatar.fromJson(
          json['avatar'],
        ).color,
        avatarIcon: Avatar.fromJson(
          json['avatar'],
        ).icon,
        avatarPic: Avatar.fromJson(
          json['avatar'],
        ).pic,
        name: json['name'] as String?,
        contactPersonUid: json['contactPersonUid'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'email': email,
        'name': name,
        'contactPersonUid': contactPersonUid,
        'avatar': Avatar(color: avatarColor, icon: avatarIcon, pic: avatarPic)
            .toJson(),
        'isFavorite': isFavorite,
      };

  Contact copyWith({
    String? uid,
    String? email,
    String? name,
    String? contactPersonUid,
    bool? isFavorite,
    String? avatarColor,
    String? avatarIcon,
    String? avatarPic,
  }) {
    return Contact(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      avatarPic: avatarPic ?? this.avatarPic,
      name: name ?? this.name,
      contactPersonUid: contactPersonUid ?? this.contactPersonUid,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
