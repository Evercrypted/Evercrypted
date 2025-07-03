import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PasswordDialog {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String description,
    required String hintText,
    required String confirmButtonText,
    required Function(String) onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.8, // 80% of screen height
      ),
      builder: (BuildContext context) {
        return _PasswordBottomSheet(
          title: title,
          description: description,
          hintText: hintText,
          confirmButtonText: confirmButtonText,
          onConfirm: onConfirm,
        );
      },
    );
  }
}

class _PasswordBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final String description;
  final String hintText;
  final String confirmButtonText;
  final Function(String) onConfirm;

  const _PasswordBottomSheet({
    required this.title,
    required this.description,
    required this.hintText,
    required this.confirmButtonText,
    required this.onConfirm,
  });

  @override
  ConsumerState<_PasswordBottomSheet> createState() =>
      _PasswordBottomSheetState();
}

class _PasswordBottomSheetState extends ConsumerState<_PasswordBottomSheet> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(keyboardProvider.notifier).close();

      // Show confirmation dialog
      showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Confirm Hide Chat'),
          content: const Text(
              'Are you sure you want to hide this chat? You will need to enter the password in the search field on chats screen to see it again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
              child: const Text('Hide Chat'),
            ),
          ],
        ),
      ).then((confirmed) {
        if (confirmed == true && mounted) {
          Navigator.pop(context); // Close bottom sheet
          widget.onConfirm(_passwordController.text);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = ref.read(keyboardProvider.notifier);

    return Wrap(
      children: [
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(defaultPadding * 2),
              topRight: Radius.circular(defaultPadding * 2),
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Container(
            margin: const EdgeInsets.all(defaultPadding),
            padding: const EdgeInsets.fromLTRB(
              defaultPadding,
              0,
              defaultPadding,
              defaultPadding,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(
                    Icons.visibility_off,
                    size: 60,
                    color: Theme.of(context).textTheme.titleMedium!.color,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: defaultPadding),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 3) {
                        return 'Password must be at least 3 characters';
                      }
                      return null;
                    },
                    onTap: () {
                      keyboardNotifier.openKeyboard(
                        controller: _passwordController,
                      );
                    },
                    keyboardType: TextInputType.none,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock,
                      ),
                      hintText: widget.hintText,
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  PrimaryButton(
                    needsActivation: true,
                    text: widget.confirmButtonText.toUpperCase(),
                    press: _submit,
                    color: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
