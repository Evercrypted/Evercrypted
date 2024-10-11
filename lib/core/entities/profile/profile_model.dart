import 'package:objectbox/objectbox.dart';

@Entity()
class Profile {
  @Id()
  int id = 0;

  final String uid;

  String? name;

  final String email;

  bool emailVerified;

  String? avatarColor;
  String? avatarIcon;
  String? avatarPic;

  Profile(
      {required this.uid,
      this.name,
      required this.email,
      this.avatarColor,
      this.avatarIcon,
      this.avatarPic,
      this.emailVerified = false});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        uid: json['uid'] as String,
        name: json['name'] as String?,
        email: (json['email'] ?? json['preverified_email']) as String,
        emailVerified: json['email_verified'] as bool,
        avatarColor: json['avatar'] == null
            ? null
            : Avatar.fromJson(
                json['avatar'],
              ).color,
        avatarIcon: json['avatar'] == null
            ? null
            : Avatar.fromJson(
                json['avatar'],
              ).icon,
        avatarPic: json['avatar'] == null
            ? null
            : Avatar.fromJson(
                json['avatar'],
              ).pic,
      );

  Profile copyWith({
    String? uid,
    String? name,
    String? email,
    bool? emailVerified,
    String? avatarColor,
    String? avatarIcon,
    String? avatarPic,
  }) {
    return Profile(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        email: email ?? this.email,
        emailVerified: emailVerified ?? this.emailVerified,
        avatarColor: avatarColor ?? this.avatarColor,
        avatarIcon: avatarIcon ?? this.avatarIcon,
        avatarPic: avatarPic ?? this.avatarPic);
  }
}

class Avatar {
  final String? color;
  final String? icon;
  final String? pic;

  Avatar({this.icon, this.color, this.pic});

  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      pic: json['pic'] as String?);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'color': color,
        'icon': icon,
        'pic': pic,
      };
}
