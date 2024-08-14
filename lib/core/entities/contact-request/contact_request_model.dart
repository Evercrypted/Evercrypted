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

  bool? unread;

  ContactRequest(
      {this.uid,
      this.authorId,
      this.authorEmail,
      this.recipientEmail,
      this.message,
      this.timeSent,
      this.queueId,
      this.unread});

  factory ContactRequest.fromJson(Map<String, dynamic> json) => ContactRequest(
        uid: json['uid'] as String?,
        authorId: json['authorId'] as String?,
        authorEmail: json['authorEmail'] as String?,
        recipientEmail: json['recipientEmail'] as String?,
        message: json['message'] as String?,
        timeSent:
            json['timeSent'] != null ? DateTime.parse(json['timeSent']) : null,
        unread: true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'authorId': authorId,
        'authorEmail': authorEmail,
        'recipientEmail': recipientEmail,
        'message': message,
        'timeSent': timeSent ?? DateTime.now().millisecondsSinceEpoch,
      };

  ContactRequest copyWith({
    String? uid,
    String? authorId,
    String? authorEmail,
    String? recipientEmail,
    String? message,
    DateTime? timeSent,
    int? queueId,
    bool? unread,
  }) {
    return ContactRequest(
      uid: uid ?? this.uid,
      authorId: authorId ?? this.authorId,
      authorEmail: authorEmail ?? this.authorEmail,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      message: message ?? this.message,
      timeSent: timeSent ?? this.timeSent,
      queueId: queueId ?? this.queueId,
      unread: unread ?? this.unread,
    );
  }
}
