// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactRequest _$ContactRequestFromJson(
        String uid, Map<String, dynamic> json) =>
    ContactRequest(
      fbUid: uid,
      authorId: json['authorId'] as String?,
      authorEmail: json['authorEmail'] as String?,
      recipientId: json['recipientId'] as String?,
      recipientEmail: json['recipientEmail'] as String?,
      message: json['message'] as String?,
      timeSent: json['timeSent'] != null
          ? json['timeSent'].toDate() as DateTime?
          : null,
      timeRejected: json['timeRejected'] != null
          ? json['timeRejected'].toDate() as DateTime?
          : null,
    );

Map<String, dynamic> _$ContactRequestToJson(ContactRequest instance) =>
    <String, dynamic>{
      'authorId': instance.authorId,
      'authorEmail': instance.authorEmail,
      'recipientId': instance.recipientId,
      'recipientEmail': instance.recipientEmail,
      'message': instance.message,
      'timeSent': instance.timeSent == null
          ? DateTime.now()
          : Timestamp.fromDate(instance.timeSent!),
      'timeRejected': instance.timeRejected == null
          ? null
          : Timestamp.fromDate(instance.timeRejected!)
    };
