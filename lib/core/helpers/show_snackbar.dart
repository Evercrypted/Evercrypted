import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

void showErrorSnackBar(BuildContext context, String text) {
  final snackBar = SnackBar(
    backgroundColor: errorColor,
    content: Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    duration: const Duration(seconds: 2), //default is 4s
    dismissDirection: DismissDirection.horizontal,
    showCloseIcon: true,
  );
  // Find the Scaffold in the widget tree and use it to show a SnackBar.
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
