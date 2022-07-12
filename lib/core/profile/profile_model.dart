import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class Profile {
  final String? fbUid;

  final String? userId;

  final String? name;

  final String? email;

  final bool? emailVerified;

  final String? profilePicRef;

  final DateTime? subscriptionEndDate;

  Profile(
      {this.fbUid,
      this.userId,
      this.name,
      this.email,
      this.emailVerified,
      this.profilePicRef,
      this.subscriptionEndDate});

  factory Profile.fromJson(String uid, Map<String, dynamic> json) =>
      _$ProfileFromJson(uid, json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}
