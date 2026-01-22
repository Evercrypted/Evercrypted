import 'package:evercrypted/core/entities/settings/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:evercrypted/widgets/secret_keyboard/keyboards.dart';
import 'package:evercrypted/core/entities/settings/settings_service.dart';

class KeyboardSettingsScreen extends StatefulWidget {
  static const routeName = '/keyboard-settings';

  const KeyboardSettingsScreen({super.key});

  @override
  State<KeyboardSettingsScreen> createState() => _KeyboardSettingsScreenState();
}

class _KeyboardSettingsScreenState extends State<KeyboardSettingsScreen> {
  Set<String> selectedKeyboards = {'English'}; // English is always selected

  @override
  void initState() {
    super.initState();
    // Load saved keyboards from database
    loadSelectedKeyboards();
  }

  void loadSelectedKeyboards() async {
    final settings = SettingsService.getSettings();
    setState(() {
      selectedKeyboards = settings != null
          ? Set<String>.from(settings.availableKeyboards)
          : {'English'};
    });
  }

  void saveSelectedKeyboards() {
    final settings = SettingsService.getSettings() ?? Settings();
    settings.availableKeyboards = selectedKeyboards.toList();
    SettingsService.saveSettings(settings);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Keyboard Languages"),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Swipe the spacebar left or right to switch between keyboard languages.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: Keyboards.availableKeyboards.length,
              itemBuilder: (context, index) {
                final keyboard = Keyboards.availableKeyboards[index];
                final isSelected = selectedKeyboards.contains(keyboard);
                final isEnglish = keyboard == 'English';

                return CheckboxListTile(
                  title: Text(keyboard),
                  value: isSelected,
                  enabled: !isEnglish, // English can't be deselected
                  onChanged: isEnglish
                      ? null
                      : (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedKeyboards.add(keyboard);
                            } else {
                              selectedKeyboards.remove(keyboard);
                            }
                          });
                        },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 50),
            child: ElevatedButton(
              onPressed: saveSelectedKeyboards,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
