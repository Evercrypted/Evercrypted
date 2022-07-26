import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'contact_request_model.g.dart';

@JsonSerializable()
class ContactRequest {
  final String? fbUid;

  final String? authorId;
  final String? authorEmail;

  final String? recipientId;
  final String? recipientEmail;

  final String? message;

  final DateTime? timeSent;

  ContactRequest({
    this.fbUid,
    this.authorId,
    this.authorEmail,
    this.recipientId,
    this.recipientEmail,
    this.message,
    this.timeSent,
  });

  factory ContactRequest.fromJson(String uid, Map<String, dynamic> json) =>
      _$ContactRequestFromJson(uid, json);

  Map<String, dynamic> toJson() => _$ContactRequestToJson(this);
}
