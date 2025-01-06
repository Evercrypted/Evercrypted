import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:evercrypted/core/services/auth_service.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isLoading = false;
  String? emailError;

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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: defaultPadding,
        right: defaultPadding,
        top: defaultPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: defaultPadding),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
            keyboardType: TextInputType.none,
            onTap: () {
              openSecretInput(
                fieldName: 'Email',
                context: context,
                controller: emailController,
                isSingleLine: true,
                done: (val) => _handleResetPassword(),
              );
            },
          ),
          const SizedBox(height: defaultPadding),
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
          const SizedBox(height: defaultPadding),
        ],
      ),
    );
  }
}
