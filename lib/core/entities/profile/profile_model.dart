import 'package:isar/isar.dart';

import '../../../models/Avatar.dart';

part 'profile_model.g.dart';

@collection
class Profile {
  Id id = Isar.autoIncrement;

  final String? uid;

  String? name;

  final String? email;

  Avatar? avatar;

  bool otpActive;

  Profile(
      {this.uid, this.name, this.email, this.avatar, this.otpActive = false});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
      uid: json['uid'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      avatar: Avatar.fromJson(
        json['avatar'],
      ),
      otpActive: json['otpActive'] ?? false);

  // Map<String, dynamic> toJson() => <String, dynamic>{
  //       'name': name,
  //       'email': email,
  //       'avatar': avatar?.toJson(),
  //       'otpActive': otpActive,
  //     };
}
