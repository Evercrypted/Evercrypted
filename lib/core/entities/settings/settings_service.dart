import 'package:evercrypted/core/entities/settings/settings_model.dart';
import 'package:evercrypted/core/obx_init.dart';

class SettingsService {
  static Settings? getSettings() {
    return ObxInit.obx.settings.getAll().firstOrNull;
  }

  static void saveSettings(Settings settings) {
    ObxInit.obx.settings.put(settings);
  }
}
