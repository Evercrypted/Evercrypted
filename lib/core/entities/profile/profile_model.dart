import 'dart:convert';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Profile {
  @Id()
  int id = 0;

  final String uid;

  @Transient()
  String? name;

  @Transient()
  String? email;

  bool emailVerified;

  bool activatedForLife;

  int activationTokenQuantity;

  @Transient()
  ProfileSubscription? subscription;

  String? get dbSubscription =>
      subscription == null ? null : jsonEncode(subscription?.toJson());

  set dbSubscription(String? value) {
    if (value == null) {
      subscription = null;
    } else {
      subscription = ProfileSubscription.fromJson(jsonDecode(value));
    }
  }

  @Transient()
  Avatar? avatar;

  String? get dbAvatar => avatar == null ? null : jsonEncode(avatar?.toJson());

  set dbAvatar(String? value) {
    if (value == null) {
      avatar = null;
    } else {
      avatar = Avatar.fromJson(jsonDecode(value));
    }
  }

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

  Profile(
      {required this.uid,
      this.name,
      this.email,
      this.avatar,
      this.emailVerified = false,
      this.activatedForLife = false,
      this.activationTokenQuantity = 0,
      this.subscription});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        uid: json['uid'] as String,
        name: json['name'] as String?,
        email: (json['email'] ?? json['preverified_email']) as String,
        emailVerified: json['email_verified'] as bool,
        avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
        subscription: json['subscription'] != null
            ? ProfileSubscription.fromJson(json['subscription'])
            : null,
        activatedForLife: json['activatedForLife'] as bool,
        activationTokenQuantity: json['activationTokenQuantity'] as int,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'name': name,
        'email': email,
        'email_verified': emailVerified,
        'avatar': avatar?.toJson(),
        'subscription': subscription?.toJson(),
        'activatedForLife': activatedForLife,
        'activationTokenQuantity': activationTokenQuantity,
      };

  Profile copyWith({
    String? uid,
    String? name,
    String? email,
    bool? emailVerified,
    Avatar? avatar,
    String? avatarIcon,
    String? avatarPic,
    ProfileSubscription? subscription,
  }) {
    return Profile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      avatar: avatar ?? this.avatar,
      subscription: subscription ?? this.subscription,
    );
  }
}

class Avatar {
  final String? color;
  final String? icon;
  final String? pic;

  Avatar({this.icon, this.color, this.pic});

  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      pic: json['pic'] as String?);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'color': color,
        'icon': icon,
        'pic': pic,
      };
}

class ProfileSubscription {
  final bool active;
  final String? type;
  final String? startDate;
  final String? endDate;

  ProfileSubscription(
      {required this.active, this.type, this.startDate, this.endDate});

  factory ProfileSubscription.fromJson(Map<String, dynamic> json) =>
      ProfileSubscription(
          active: json['active'] as bool,
          type: json['type'] as String?,
          startDate: json['from'] as String?,
          endDate: json['to'] as String?);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'active': active,
        'type': type,
        'from': startDate,
        'to': endDate,
      };
}
