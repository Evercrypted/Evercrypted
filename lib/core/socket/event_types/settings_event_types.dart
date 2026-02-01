class SettingsEventTypes {
  SettingsEventTypes._();
  static const getActivate2FA = 'getActivate2FA';
  static const activate2FA = 'activate2FA';
  static const deactivate2FA = 'deactivate2FA';
  static const login2FA = 'login2FA';
  static const redeemActivationCode = 'redeemActivationCode';
  static const reportContent = 'reportContent';
  static const blockUser = 'blockUser';
  static const unblockUser = 'unblockUser';
  static const userBlocked = 'userBlocked'; // Received when someone blocks you
}

/// Predefined report reasons matching server-side ReportReason enum
class ReportReasons {
  ReportReasons._();
  static const spam = 'spam';
  static const harassment = 'harassment';
  static const inappropriateContent = 'inappropriate_content';
  static const hateSpeech = 'hate_speech';
  static const violence = 'violence';
  static const other = 'other';

  static List<Map<String, String>> get options => [
        {'value': spam, 'label': 'Spam'},
        {'value': harassment, 'label': 'Harassment'},
        {'value': inappropriateContent, 'label': 'Inappropriate Content'},
        {'value': hateSpeech, 'label': 'Hate Speech'},
        {'value': violence, 'label': 'Violence or Threats'},
        {'value': other, 'label': 'Other'},
      ];
}
