// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoom _$ChatRoomFromJson(String uid, Map<String, dynamic> json) => ChatRoom(
      fbUid: uid,
      messageLongevityMinutes: json['messageLongevityMinutes'] as int?,
      name: json['name'] as String,
      picRef: json['picRef'] as String?,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      lastMessageTime:
          json['lastMessageTime'].toDate() as DateTime? ?? DateTime.now(),
    );

Map<String, dynamic> _$ChatRoomToJson(ChatRoom instance) => <String, dynamic>{
      'fbUid': instance.fbUid,
      'messageLongevityMinutes': instance.messageLongevityMinutes,
      'name': instance.name,
      'picRef': instance.picRef,
      'participants': instance.participants,
      'lastMessageTime': Timestamp.fromDate(instance.lastMessageTime),
    };
