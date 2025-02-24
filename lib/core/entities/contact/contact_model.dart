import 'dart:convert';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
import 'package:objectbox/objectbox.dart';

import '../profile/profile_model.dart';

@Entity()
class Contact {
  @Id()
  int id = 0;

  @Unique()
  final String? uid;

  @Transient()
  String? email;

  @Transient()
  String? name;

  @Unique()
  final String? contactPersonUid;

  @Transient()
  Avatar? avatar;

  String? get dbAvatar => avatar == null ? null : jsonEncode(avatar?.toJson());

  set dbAvatar(String? value) {
    if (value == null || value == 'null') {
      avatar = null;
    } else {
      avatar = Avatar.fromJson(jsonDecode(value));
    }
  }

  bool isFavorite;

  String? get dbEmail {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      return email;
    } else {
      return fernetEncrypt(email, appKey);
    }
  }

  set dbEmail(String? value) {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      email = value;
      return;
    } else {
      email = fernetDecrypt(value, appKey);
    }
  }

  String? get dbName {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      return name;
    } else {
      return fernetEncrypt(name, appKey);
    }
  }

  set dbName(String? value) {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      name = value;
      return;
    } else {
      name = fernetDecrypt(value, appKey);
    }
  }

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
    String? name,
    String? contactPersonUid,
    bool? isFavorite,
    Avatar? avatar,
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
