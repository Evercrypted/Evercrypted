import 'package:evercrypted/core/entities/settings/settings_model.dart';
import 'package:evercrypted/main.dart';

class SettingsService {
  static Settings? getSettings() {
    return obx.settings.getAll().firstOrNull;
  }

  static void saveSettings(Settings settings) {
    obx.settings.put(settings);
  }
}
