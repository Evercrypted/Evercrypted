import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:evercrypted/core/constants/profanity_words.dart';

final profanityFilterServiceProvider = Provider<ProfanityFilterService>((ref) {
  return ProfanityFilterService();
});

class ProfanityFilterService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    aOptions: AndroidOptions(),
  );

  static const _storageKey = 'profanity_filter_enabled';

  /// Check if the message contains any profanity words.
  /// Returns the first detected profanity word, or null if none found.
  String? containsProfanity(String message) {
    final lowerMessage = message.toLowerCase();

    for (final word in profanityWords) {
      // Check for word boundaries to avoid false positives
      // e.g., "class" should not match "ass"
      final pattern = RegExp(
        r'(^|[^a-zA-Z])' + RegExp.escape(word) + r'([^a-zA-Z]|$)',
        caseSensitive: false,
      );

      if (pattern.hasMatch(lowerMessage)) {
        return word;
      }
    }

    return null;
  }

  /// Check if profanity filter is enabled (defaults to true)
  Future<bool> isEnabled() async {
    try {
      final value = await _storage.read(key: _storageKey);
      // Default to true if not set
      if (value == null) return true;
      return value == 'true';
    } catch (e) {
      return true; // Default to enabled
    }
  }

  /// Enable or disable the profanity filter
  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _storageKey, value: enabled.toString());
  }
}
