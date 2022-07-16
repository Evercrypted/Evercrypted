import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class Profile {
  final String? fbUid;

  final String? userId;

  String? name;

  final String? email;

  bool? emailVerified;

  String? profilePicRef;

  Profile(
      {this.fbUid,
      this.userId,
      this.name,
      this.email,
      this.emailVerified,
      this.profilePicRef});

  factory Profile.fromJson(String uid, Map<String, dynamic> json) =>
      _$ProfileFromJson(uid, json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}
