import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Let's apply light and dark theme on our app

ThemeData lightThemeData(BuildContext context) {
  return ThemeData.light().copyWith(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
    ),
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
      selectedItemColor: contentColorLightTheme.withAlpha((255 * 0.7).round()),
      unselectedItemColor:
          contentColorLightTheme.withAlpha((255 * 0.32).round()),
      selectedIconTheme: const IconThemeData(color: primaryColor),
      showUnselectedLabels: true,
    ),
    inputDecorationTheme: inputDecorationTheme.copyWith(
        fillColor: primaryColor.withAlpha((255 * 0.05).round())),
  );
}

ThemeData darkThemeData(BuildContext context) {
  // Bydefault flutter provie us light and dark theme
  // we just modify it as our need
  return ThemeData.dark().copyWith(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: contentColorLightTheme,
    dialogTheme: DialogThemeData(
      backgroundColor: contentColorLightThemeSecondary,
    ),
    appBarTheme: appBarTheme.copyWith(
      backgroundColor: contentColorLightTheme,
    ),
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
      unselectedItemColor:
          contentColorDarkTheme.withAlpha((255 * 0.32).round()),
      selectedIconTheme: const IconThemeData(color: primaryColor),
      showUnselectedLabels: true,
    ),
    inputDecorationTheme: inputDecorationTheme.copyWith(
      fillColor: contentColorLightThemeSecondary,
    ),
  );
}

const appBarTheme = AppBarTheme(centerTitle: false, elevation: 0);
final inputDecorationTheme = InputDecorationTheme(
  filled: true,
  fillColor: contentColorDarkTheme.withAlpha((255 * 0.08).round()),
  contentPadding: const EdgeInsets.symmetric(
      horizontal: defaultPadding * 1.5, vertical: defaultPadding * 0.9),
  border: UnderlineInputBorder(
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.circular(40),
  ),
);
