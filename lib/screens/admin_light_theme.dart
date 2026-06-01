import 'package:flutter/material.dart';

ThemeData buildAdminLightTheme(BuildContext context) {
  const primaryText = Color(0xFF0A2342);
  const secondaryText = Color(0xFF6B7A90);
  const divider = Color(0xFFE5E7EB);
  const fill = Colors.white;

  final base = Theme.of(context);
  final lightBase = ThemeData.light(useMaterial3: true);
  return lightBase.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    cardColor: Colors.white,
    canvasColor: Colors.white,
    shadowColor: Colors.black.withOpacity(0.08),
    dialogBackgroundColor: Colors.white,
    dividerColor: divider,
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.light,
      primary: const Color(0xFF2F6BFF),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: primaryText,
      secondary: const Color(0xFF2F6BFF),
      onSecondary: Colors.white,
      error: const Color(0xFFB42318),
      onError: Colors.white,
    ),
    textTheme: lightBase.textTheme.apply(
      bodyColor: primaryText,
      displayColor: primaryText,
    ),
    primaryTextTheme: lightBase.primaryTextTheme.apply(
      bodyColor: primaryText,
      displayColor: primaryText,
    ),
    iconTheme: const IconThemeData(color: primaryText),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F8FA),
      foregroundColor: primaryText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: primaryText),
      titleTextStyle: TextStyle(
        color: primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: secondaryText,
        fontSize: 16,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF2F6BFF), width: 2),
      ),
      labelStyle: TextStyle(color: secondaryText),
      hintStyle: TextStyle(color: secondaryText),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF2F6BFF),
      selectionColor: Color(0x332F6BFF),
      selectionHandleColor: Color(0xFF2F6BFF),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primaryText,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,
      textStyle: TextStyle(color: primaryText),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: primaryText),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: primaryText,
      iconColor: primaryText,
    ),
  );
}
