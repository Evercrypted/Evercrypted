import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_room_model.g.dart';

@JsonSerializable()
class ChatRoom {
  final String? fbUid;

  final int? messageLongevityMinutes;
  final String? name;

  final String? picRef;

  final List<String>? participants;

  final DateTime? lastMessageTime;

  ChatRoom({
    this.fbUid,
    this.messageLongevityMinutes,
    this.name,
    this.picRef,
    this.participants,
    this.lastMessageTime,
  });

  factory ChatRoom.fromJson(String uid, Map<String, dynamic> json) =>
      _$ChatRoomFromJson(uid, json);

  Map<String, dynamic> toJson() => _$ChatRoomToJson(this);
}
