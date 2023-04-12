// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(String uid, Map<String, dynamic> json) => Profile(
    fbUid: uid,
    name: json['name'] as String?,
    email: json['email'] as String?,
    emailVerified: json['emailVerified'] as bool?,
    avatar: Avatar.fromJson(json['avatar'] as Map<String, dynamic>));

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'emailVerified': instance.emailVerified,
      'avatar': instance.avatar?.toJson(),
    };
