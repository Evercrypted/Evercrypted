import 'package:isar/isar.dart';

part 'profile_model.g.dart';

@embedded
class Avatar {
  final String? color;
  final String? icon;

  Avatar({this.icon, this.color});

  factory Avatar.fromJson(Map<String, dynamic> json) =>
      Avatar(color: json['color'] as String, icon: json['icon'] as String);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'color': color,
        'icon': icon,
      };
}

@collection
class Profile {
  Id id = Isar.autoIncrement;

  final String? uid;

  String? name;

  final String? email;

  Avatar? avatar;

  Profile({this.uid, this.name, this.email, this.avatar});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
      uid: json['uid'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatar: Avatar.fromJson(
        json['avatar'],
      ));

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'avatar': avatar?.toJson(),
      };
}
