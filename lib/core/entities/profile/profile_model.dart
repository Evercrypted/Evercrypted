import 'dart:convert';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/db_encryption.dart';
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
  AccountSettings? accountSettings;

  String? get dbAccountSettings =>
      accountSettings == null ? null : jsonEncode(accountSettings?.toJson());

  set dbAccountSettings(String? value) {
    accountSettings =
        value == null ? null : AccountSettings.fromJson(jsonDecode(value));
  }

  @Transient()
  ProfileSubscription? subscription;

  String? get dbSubscription =>
      subscription == null ? null : jsonEncode(subscription?.toJson());

  set dbSubscription(String? value) {
    subscription =
        value == null ? null : ProfileSubscription.fromJson(jsonDecode(value));
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

  @Transient()
  List<BlockedUser>? blockedUsers;

  String? get dbBlockedUsers => blockedUsers == null
      ? null
      : jsonEncode(blockedUsers?.map((e) => e.toJson()).toList());

  set dbBlockedUsers(String? value) {
    blockedUsers = value == null
        ? null
        : (jsonDecode(value) as List)
            .map((e) => BlockedUser.fromJson(e))
            .toList();
  }

  @Transient()
  ProfileSettings? settings;

  String? get dbSettings =>
      settings == null ? null : jsonEncode(settings?.toJson());

  set dbSettings(String? value) {
    settings =
        value == null ? null : ProfileSettings.fromJson(jsonDecode(value));
  }

  String? get dbEmail {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      return email;
    } else {
      return encryptForDb(email, appKey);
    }
  }

  set dbEmail(String? value) {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      email = value;
      return;
    } else {
      email = decryptForDb(value, appKey);
    }
  }

  String? get dbName {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      return name;
    } else {
      return encryptForDb(name, appKey);
    }
  }

  set dbName(String? value) {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      name = value;
      return;
    } else {
      name = decryptForDb(value, appKey);
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
      this.subscription,
      this.accountSettings,
      this.blockedUsers,
      this.settings});

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
        accountSettings: json['accountSettings'] != null
            ? AccountSettings.fromJson(json['accountSettings'])
            : null,
        // Server sends blocked_users (snake_case), local storage uses blockedUsers (camelCase)
        blockedUsers: (json['blocked_users'] ?? json['blockedUsers']) != null
            ? ((json['blocked_users'] ?? json['blockedUsers']) as List)
                .map((e) => BlockedUser.fromJson(e))
                .toList()
            : null,
        settings: json['settings'] != null
            ? ProfileSettings.fromJson(json['settings'])
            : null,
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
        'accountSettings': accountSettings?.toJson(),
        'blockedUsers': blockedUsers?.map((e) => e.toJson()).toList(),
        'settings': settings?.toJson(),
      };

  Profile copyWith({
    String? uid,
    String? name,
    String? email,
    bool? emailVerified,
    Avatar? avatar,
    ProfileSubscription? subscription,
    AccountSettings? accountSettings,
    bool? activatedForLife,
    int? activationTokenQuantity,
    List<BlockedUser>? blockedUsers,
    ProfileSettings? settings,
  }) {
    return Profile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      avatar: avatar ?? this.avatar,
      subscription: subscription ?? this.subscription,
      accountSettings: accountSettings ?? this.accountSettings,
      activatedForLife: activatedForLife ?? this.activatedForLife,
      activationTokenQuantity:
          activationTokenQuantity ?? this.activationTokenQuantity,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      settings: settings ?? this.settings,
    );
  }
}

class ProfileSettings {
  final bool? blocked;
  final String? blockedUntil; // ISO date string

  ProfileSettings({this.blocked, this.blockedUntil});

  /// Check if the account is currently blocked
  bool get isBlocked {
    if (blocked == true) return true;
    if (blockedUntil != null) {
      final until = DateTime.tryParse(blockedUntil!);
      if (until != null && until.isAfter(DateTime.now())) return true;
    }
    return false;
  }

  factory ProfileSettings.fromJson(Map<String, dynamic> json) =>
      ProfileSettings(
        blocked: json['blocked'] as bool?,
        blockedUntil: json['blocked_until'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'blocked': blocked,
        'blocked_until': blockedUntil,
      };
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
  final String? type;
  final String? startDate;
  final String? endDate;
  final String? appleTransactionId;
  final String? appleProductId;
  final bool? autoRenew;
  final bool? inGracePeriod;

  ProfileSubscription({
    this.type,
    this.startDate,
    this.endDate,
    this.appleTransactionId,
    this.appleProductId,
    this.autoRenew,
    this.inGracePeriod,
  });

  /// Check if subscription is currently active
  /// A subscription is active if endDate is in the future
  bool get isActive {
    if (endDate == null) {
      return false;
    }
    final end = DateTime.tryParse(endDate!);
    if (end == null) {
      return false;
    }
    final isAfter = end.isAfter(DateTime.now());
    return isAfter;
  }

  factory ProfileSubscription.fromJson(Map<String, dynamic> json) =>
      ProfileSubscription(
        type: json['type'] as String?,
        startDate: json['startDate'] as String?,
        endDate: json['endDate'] as String?,
        appleTransactionId: json['appleTransactionId'] as String?,
        appleProductId: json['appleProductId'] as String?,
        autoRenew: json['autoRenew'] as bool?,
        inGracePeriod: json['inGracePeriod'] as bool?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'startDate': startDate,
        'endDate': endDate,
        'appleTransactionId': appleTransactionId,
        'appleProductId': appleProductId,
        'autoRenew': autoRenew,
        'inGracePeriod': inGracePeriod,
      };

  ProfileSubscription copyWith({
    String? type,
    String? startDate,
    String? endDate,
    String? appleTransactionId,
    String? appleProductId,
    bool? autoRenew,
    bool? inGracePeriod,
  }) {
    return ProfileSubscription(
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      appleTransactionId: appleTransactionId ?? this.appleTransactionId,
      appleProductId: appleProductId ?? this.appleProductId,
      autoRenew: autoRenew ?? this.autoRenew,
      inGracePeriod: inGracePeriod ?? this.inGracePeriod,
    );
  }
}

class AccountSettings {
  final String? appIcon;
  final Map<String, dynamic>? hiddenChats;
  final Map<String, dynamic>? hiddenContacts;

  AccountSettings({this.appIcon, this.hiddenChats, this.hiddenContacts});

  factory AccountSettings.fromJson(Map<String, dynamic> json) =>
      AccountSettings(
          appIcon: json['appIcon'] as String?,
          hiddenChats: json['hiddenChats'] as Map<String, dynamic>?,
          hiddenContacts: json['hiddenContacts'] as Map<String, dynamic>?);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'appIcon': appIcon,
        'hiddenChats': hiddenChats,
        'hiddenContacts': hiddenContacts,
      };
}

class BlockedUser {
  final String uid;
  final String email;
  final String name;

  BlockedUser({required this.uid, required this.email, required this.name});

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        uid: json['uid'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'email': email,
        'name': name,
      };
}
