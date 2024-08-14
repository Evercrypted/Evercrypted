import 'package:isar/isar.dart';

import '../profile/profile_model.dart';

part 'contact_model.g.dart';

@collection
class Contact {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String? uid;

  final String? email;

  @Index(unique: true)
  final String? contactPersonUid;

  Avatar? avatar;

  String? name;

  bool isFavorite;

  Contact(
      {this.uid,
      this.email,
      this.avatar,
      this.name,
      this.contactPersonUid,
      this.isFavorite = false});

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        uid: json['uid'] as String?,
        email: json['email'] as String?,
        avatar: json['avatar'] != null
            ? Avatar.fromJson(
                json['avatar'],
              )
            : null,
        name: json['name'] as String?,
        contactPersonUid: json['contactPersonUid'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'email': email,
        'name': name,
        'contactPersonUid': contactPersonUid,
        'avatar': avatar?.toJson(),
        'isFavorite': isFavorite,
      };

  Contact copyWith({
    String? uid,
    String? email,
    Avatar? avatar,
    String? name,
    String? contactPersonUid,
    bool? isFavorite,
  }) {
    return Contact(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      name: name ?? this.name,
      contactPersonUid: contactPersonUid ?? this.contactPersonUid,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
