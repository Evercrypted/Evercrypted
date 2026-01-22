import 'dart:convert';
import 'package:objectbox/objectbox.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/db_encryption.dart';

@Entity()
class Settings {
  @Id()
  int id = 0;

  @Transient()
  List<String> availableKeyboards;

  @Transient()
  String lastUsedKeyboard;

  String? get dbLastUsedKeyboard {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      return lastUsedKeyboard;
    } else {
      return encryptForDb(lastUsedKeyboard, appKey);
    }
  }

  set dbLastUsedKeyboard(String? value) {
    final String? appKey = Auth.appKey;
    if (value == null) {
      lastUsedKeyboard = 'English';
    } else {
      if (appKey == null) {
        lastUsedKeyboard = value;
      } else {
        lastUsedKeyboard = decryptForDb(value, appKey) ?? 'English';
      }
    }
  }

  String? get dbAvailableKeyboards {
    final String? appKey = Auth.appKey;
    if (appKey == null) {
      return jsonEncode(availableKeyboards);
    } else {
      return encryptForDb(jsonEncode(availableKeyboards), appKey);
    }
  }

  set dbAvailableKeyboards(String? value) {
    final String? appKey = Auth.appKey;
    if (value == null) {
      availableKeyboards = ['English'];
    } else {
      if (appKey == null) {
        availableKeyboards = List<String>.from(jsonDecode(value));
      } else {
        availableKeyboards = List<String>.from(
            jsonDecode(decryptForDb(value, appKey) ?? '["English"]'));
      }
    }
  }

  Settings({
    this.availableKeyboards = const ['English'],
    this.lastUsedKeyboard = 'English',
  });

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        availableKeyboards:
            List<String>.from(json['availableKeyboards'] ?? ['English']),
        lastUsedKeyboard: json['lastUsedKeyboard'] ?? 'English',
      );

  Map<String, dynamic> toJson() => {
        'availableKeyboards': availableKeyboards,
        'lastUsedKeyboard': lastUsedKeyboard,
      };
}
