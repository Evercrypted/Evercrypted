import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class AppLinkService {
  static const String host = 'evercrypted.com';
  static const String addContactPath = '/add-contact';

  static final AppLinks _appLinks = AppLinks();

  /// Build a share URL for adding a contact
  static Uri buildShareLink(String email) {
    return Uri.https(host, addContactPath, {'email': email});
  }

  /// Parse an incoming URI and extract the contact email if valid
  static String? parseContactEmail(Uri uri) {
    if (uri.host == host && uri.path == addContactPath) {
      return uri.queryParameters['email'];
    }
    return null;
  }

  /// Get the initial link that launched the app (cold start)
  static Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } catch (e) {
      debugPrint('AppLinkService: Error getting initial link: $e');
      return null;
    }
  }

  /// Stream of incoming links (warm start / app already running)
  static Stream<Uri> get onLinkStream => _appLinks.uriLinkStream;
}
