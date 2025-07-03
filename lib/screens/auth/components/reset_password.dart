import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';

class ResetPassword extends ConsumerStatefulWidget {
  const ResetPassword({super.key});

  @override
  ResetPasswordState createState() => ResetPasswordState();
}

class ResetPasswordState extends ConsumerState<ResetPassword> {
  final TextEditingController emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;
  String? emailError;

  @override
  void initState() {
    super.initState();
    if (Auth.getUser != null) {
      emailController.text = Auth.getUser!.email;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    // Email validation regex pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (emailController.text.isEmpty) {
      setState(() {
        emailError = 'Please enter your email address';
      });
      return;
    }

    if (!emailRegex.hasMatch(emailController.text)) {
      setState(() {
        emailError = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      emailError = null;
      isLoading = true;
    });

    _authService.forgotPassword(emailController.text).then((result) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset email sent to ${emailController.text}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: secondaryColor,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
        ),
      );
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: errorColor,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = ref.watch(keyboardProvider.notifier);

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(defaultPadding * 2),
            topRight: Radius.circular(defaultPadding * 2),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: defaultPadding,
          right: defaultPadding,
          top: defaultPadding * 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.refresh,
                size: 40,
                color: Theme.of(context).textTheme.titleMedium!.color),
            const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: defaultPadding * 2),
            const Text(
              'Reset Password link will be sent to your email address',
              style: TextStyle(
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: defaultPadding),
            TextFormField(
              readOnly: Auth.getUser != null,
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              keyboardType: TextInputType.none,
              onTap: () {
                if (Auth.getUser != null) {
                  return;
                }
                keyboardNotifier.openKeyboard(controller: emailController);
              },
            ),
            const SizedBox(height: defaultPadding * 2),
            PrimaryButton(
              text: 'Submit',
              press: _handleResetPassword,
              child: isLoading
                  ? const SpinKitThreeBounce(
                      color: Colors.white,
                      size: 17,
                    )
                  : null,
            ),
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}
