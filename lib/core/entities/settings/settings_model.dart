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
  });

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        availableKeyboards:
            List<String>.from(json['availableKeyboards'] ?? ['English']),
      );

  Map<String, dynamic> toJson() => {
        'availableKeyboards': availableKeyboards,
      };
}
