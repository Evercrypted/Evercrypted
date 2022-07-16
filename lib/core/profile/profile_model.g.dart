// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(String uid, Map<String, dynamic> json) => Profile(
      fbUid: uid,
      userId: json['userId'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      emailVerified: json['emailVerified'] as bool?,
      profilePicRef: json['profilePicRef'] as String?,
    );

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'emailVerified': instance.emailVerified,
      'profilePicRef': instance.profilePicRef,
    };
