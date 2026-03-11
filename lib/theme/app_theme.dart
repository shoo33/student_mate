import 'package:flutter/material.dart';

class AppTheme {
  static const Color rose = Color(0xFFB76E79);
  static const Color dark = Color(0xFF2C1E1E);

  static const Color bgTop = Color(0xFFF7D8D2);
  static const Color bgBottom = Color(0xFFF3E8E4);

  static const Color card = Color(0xFFDDB7AE);
  static const Color beigeBtn = Color(0xFFE9D2C8);
  static const Color overdueRed = Color(0xFFC0392B);

  static const Color quoteCardLight = Color(0xFF9B858C);

  static const Color darkBgTop = Color(0xFF1E1A1C);
  static const Color darkBgBottom = Color(0xFF151214);
  static const Color darkCard = Color(0xFF3A2A2F);
  static const Color darkCardSoft = Color(0xFF4A383E);
  static const Color darkText = Color(0xFFF7EAE7);
  static const Color darkMuted = Color(0xFFD8C3BE);
  static const Color quoteCardDark = Color(0xFF5D4C52);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageTop(BuildContext context) =>
      isDark(context) ? darkBgTop : bgTop;

  static Color pageBottom(BuildContext context) =>
      isDark(context) ? darkBgBottom : bgBottom;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? darkCard : card;

  static Color softCardColor(BuildContext context) =>
      isDark(context) ? darkCardSoft : const Color(0xFFF2C9BF);

  static Color profileHeaderColor(BuildContext context) =>
      isDark(context) ? quoteCardDark : quoteCardLight;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkText : dark;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? darkMuted : Colors.black87;

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgBottom,
      primaryColor: rose,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: rose,
        brightness: Brightness.light,
        primary: rose,
        surface: bgBottom,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: dark,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFF1ECF3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F1EE),
        labelStyle: TextStyle(
          color: dark.withValues(alpha: 0.75),
          fontWeight: FontWeight.w800,
        ),
        hintStyle: TextStyle(
          color: dark.withValues(alpha: 0.45),
          fontWeight: FontWeight.w700,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dark.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dark, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: bgBottom,
        hourMinuteTextColor: dark,
        hourMinuteColor: beigeBtn,
        dayPeriodTextColor: dark,
        dayPeriodColor: beigeBtn,
        dayPeriodBorderSide: BorderSide(color: dark.withValues(alpha: 0.25)),
        dialBackgroundColor: beigeBtn.withValues(alpha: 0.45),
        dialHandColor: dark,
        entryModeIconColor: dark,
        helpTextStyle: const TextStyle(
          color: dark,
          fontWeight: FontWeight.w900,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: dark,
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: dark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: bgBottom,
        headerBackgroundColor: rose,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return dark;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return rose;
          return null;
        }),
        todayForegroundColor: const WidgetStatePropertyAll(rose),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: rose,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return rose;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return rose.withValues(alpha: 0.35);
          }
          return Colors.grey.shade300;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: rose,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBgBottom,
      primaryColor: rose,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: rose,
        brightness: Brightness.dark,
        primary: rose,
        surface: darkBgBottom,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkText,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2A2327),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      cardColor: darkCard,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF32292D),
        labelStyle: const TextStyle(
          color: darkMuted,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: TextStyle(
          color: darkMuted.withValues(alpha: 0.70),
          fontWeight: FontWeight.w700,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkMuted.withValues(alpha: 0.20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: rose, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2327),
        contentTextStyle: const TextStyle(
          color: darkText,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: const Color(0xFF2A2327),
        hourMinuteTextColor: darkText,
        hourMinuteColor: darkCard,
        dayPeriodTextColor: darkText,
        dayPeriodColor: darkCard,
        dayPeriodBorderSide:
            BorderSide(color: darkMuted.withValues(alpha: 0.25)),
        dialBackgroundColor: darkCard.withValues(alpha: 0.70),
        dialHandColor: rose,
        entryModeIconColor: darkText,
        helpTextStyle: const TextStyle(
          color: darkText,
          fontWeight: FontWeight.w900,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: darkText,
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: darkText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: const Color(0xFF2A2327),
        headerBackgroundColor: rose,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return darkText;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return rose;
          return null;
        }),
        todayForegroundColor: const WidgetStatePropertyAll(rose),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: rose,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return rose;
          return darkMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return rose.withValues(alpha: 0.35);
          }
          return Colors.white.withValues(alpha: 0.18);
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: rose,
      ),
    );
  }
}