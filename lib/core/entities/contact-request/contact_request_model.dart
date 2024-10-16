import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class ContactRequest {
  @Id()
  int id = 0;

  @Unique()
  final String? uid;

  final String? authorId;

  @Transient()
  String? authorEmail;
  @Transient()
  String? recipientEmail;

  @Transient()
  String? message;

  @Property(type: PropertyType.date)
  final DateTime? timeSent;

  final int? queueId;

  bool? unread;

  String? get dbAuthorEmail {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      return authorEmail;
    } else {
      return fernetEncrypt(authorEmail, appKey);
    }
  }

  set dbAuthorEmail(String? value) {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      authorEmail = value;
      return;
    } else {
      authorEmail = fernetDecrypt(value, appKey);
    }
  }

  String? get dbRecipientEmail {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      return recipientEmail;
    } else {
      return fernetEncrypt(recipientEmail, appKey);
    }
  }

  set dbRecipientEmail(String? value) {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      recipientEmail = value;
      return;
    } else {
      recipientEmail = fernetDecrypt(value, appKey);
    }
  }

  String? get dbMessage {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      return message;
    } else {
      return fernetEncrypt(message, appKey);
    }
  }

  set dbMessage(String? value) {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      message = value;
      return;
    } else {
      message = fernetDecrypt(value, appKey);
    }
  }

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
