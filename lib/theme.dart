import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Let's apply light and dark theme on our app

ThemeData lightThemeData(BuildContext context) {
  return ThemeData.light().copyWith(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: appBarTheme,
    iconTheme: const IconThemeData(color: contentColorLightTheme),
    textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
        .apply(bodyColor: contentColorLightTheme),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: contentColorLightTheme.withOpacity(0.7),
      unselectedItemColor: contentColorLightTheme.withOpacity(0.32),
      selectedIconTheme: const IconThemeData(color: primaryColor),
      showUnselectedLabels: true,
    ),
    inputDecorationTheme: inputDecorationTheme.copyWith(
        fillColor: primaryColor.withOpacity(0.05)),
  );
}

ThemeData darkThemeData(BuildContext context) {
  // Bydefault flutter provie us light and dark theme
  // we just modify it as our need
  return ThemeData.dark().copyWith(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: contentColorLightTheme,
    appBarTheme: appBarTheme,
    iconTheme: const IconThemeData(color: contentColorDarkTheme),
    textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
        .apply(bodyColor: contentColorDarkTheme),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: contentColorLightTheme,
      selectedItemColor: Colors.white70,
      unselectedItemColor: contentColorDarkTheme.withOpacity(0.32),
      selectedIconTheme: const IconThemeData(color: primaryColor),
      showUnselectedLabels: true,
    ),
    inputDecorationTheme: inputDecorationTheme,
  );
}

const appBarTheme = AppBarTheme(centerTitle: false, elevation: 0);
final inputDecorationTheme = InputDecorationTheme(
  filled: true,
  fillColor: contentColorDarkTheme.withOpacity(0.08),
  contentPadding: const EdgeInsets.symmetric(
      horizontal: defaultPadding * 1.5, vertical: defaultPadding),
  border: const OutlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.all(Radius.circular(50)),
  ),
);
