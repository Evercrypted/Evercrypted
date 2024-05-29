import 'package:isar/isar.dart';

part 'profile_model.g.dart';

@collection
class Profile {
  Id id = Isar.autoIncrement;

  final String uid;

  String? name;

  final String email;

  bool emailVerified;

  Avatar? avatar;

  Profile(
      {required this.uid,
      this.name,
      required this.email,
      this.avatar,
      this.emailVerified = false});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
      uid: json['uid'] as String,
      name: json['name'] as String?,
      email: json['email'] as String,
      emailVerified: json['email_verified'] as bool,
      avatar: json['avatar'] == null
          ? null
          : Avatar.fromJson(
              json['avatar'],
            ));

  // Map<String, dynamic> toJson() => <String, dynamic>{
  //       'name': name,
  //       'email': email,
  //       'avatar': avatar?.toJson(),
  //     };
}

@embedded
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
