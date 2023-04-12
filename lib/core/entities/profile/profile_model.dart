import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

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

@JsonSerializable()
class Profile {
  final String? fbUid;

  String? name;

  final String? email;

  bool? emailVerified;

  Avatar? avatar;

  Profile({this.fbUid, this.name, this.email, this.emailVerified, this.avatar});

  factory Profile.fromJson(String uid, Map<String, dynamic> json) =>
      _$ProfileFromJson(uid, json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}
