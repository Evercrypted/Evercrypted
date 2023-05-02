import 'package:isar/isar.dart';

part 'contact_request_model.g.dart';

@collection
class ContactRequest {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String? uid;

  final String? authorId;
  final String? authorEmail;

  final String? recipientEmail;

  final String? message;

  final DateTime? timeSent;

  final int? queueId;

  ContactRequest(
      {this.uid,
      this.authorId,
      this.authorEmail,
      this.recipientEmail,
      this.message,
      this.timeSent,
      this.queueId});

  factory ContactRequest.fromJson(Map<String, dynamic> json) => ContactRequest(
        uid: json['uid'] as String?,
        authorId: json['authorId'] as String?,
        authorEmail: json['authorEmail'] as String?,
        recipientEmail: json['recipientEmail'] as String?,
        message: json['message'] as String?,
        timeSent:
            json['timeSent'] != null ? DateTime.parse(json['timeSent']) : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'authorId': authorId,
        'authorEmail': authorEmail,
        'recipientEmail': recipientEmail,
        'message': message,
        'timeSent': timeSent ?? DateTime.now().millisecondsSinceEpoch,
      };
}
