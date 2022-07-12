// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../core/profile/profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(String uid, Map<String, dynamic> json) => Profile(
      fbUid: uid,
      userId: json['userId'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      profilePicRef: json['profilePicRef'] as String?,
      subscriptionEndDate: json['subscriptionEndDate'] == null
          ? null
          : DateTime.parse(json['subscriptionEndDate'] as String),
    );

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'profilePicRef': instance.profilePicRef,
      'subscriptionEndDate': instance.subscriptionEndDate?.toIso8601String(),
    };
