import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:isar/isar.dart';

part 'contact_model.g.dart';

@collection
class Contact {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String? uid;

  final String? email;

  final Avatar? avatar;

  final String? name;

  Contact({this.uid, this.email, this.avatar, this.name});

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        uid: json['uid'] as String?,
        email: json['contactEmail'] as String?,
        avatar: Avatar.fromJson(json['authorEmail']),
        name: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'email': email,
        'name': name,
        'avatar': avatar?.toJson(),
      };
}
