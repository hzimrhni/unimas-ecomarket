import 'package:flutter/material.dart';

@immutable
class StudentAppColors extends ThemeExtension<StudentAppColors> {
  final Color cardBackground;
  final Color softBackground;
  final Color border;
  final Color divider;
  final Color secondaryText;
  final Color tertiaryText;
  final Color shadow;
  final Color bubbleSurface;
  final Color navBackground;

  const StudentAppColors({
    required this.cardBackground,
    required this.softBackground,
    required this.border,
    required this.divider,
    required this.secondaryText,
    required this.tertiaryText,
    required this.shadow,
    required this.bubbleSurface,
    required this.navBackground,
  });

  const StudentAppColors.light()
      : cardBackground = Colors.white,
        softBackground = const Color(0xFFF3F4F6),
        border = const Color(0xFFE5E7EB),
        divider = const Color(0xFFE5E7EB),
        secondaryText = const Color(0xFF667085),
        tertiaryText = const Color(0xFF98A2B3),
        shadow = const Color(0x0D000000),
        bubbleSurface = const Color(0xFFE9EEF5),
        navBackground = Colors.white;

  const StudentAppColors.dark()
      : cardBackground = const Color(0xFF17191F),
        softBackground = const Color(0xFF1D2129),
        border = const Color(0x1AFFFFFF),
        divider = const Color(0x1FFFFFFF),
        secondaryText = const Color(0xB3FFFFFF),
        tertiaryText = const Color(0x99FFFFFF),
        shadow = Colors.transparent,
        bubbleSurface = const Color(0xFF232834),
        navBackground = const Color(0xFF14171D);

  @override
  StudentAppColors copyWith({
    Color? cardBackground,
    Color? softBackground,
    Color? border,
    Color? divider,
    Color? secondaryText,
    Color? tertiaryText,
    Color? shadow,
    Color? bubbleSurface,
    Color? navBackground,
  }) {
    return StudentAppColors(
      cardBackground: cardBackground ?? this.cardBackground,
      softBackground: softBackground ?? this.softBackground,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      shadow: shadow ?? this.shadow,
      bubbleSurface: bubbleSurface ?? this.bubbleSurface,
      navBackground: navBackground ?? this.navBackground,
    );
  }

  @override
  StudentAppColors lerp(ThemeExtension<StudentAppColors>? other, double t) {
    if (other is! StudentAppColors) {
      return this;
    }
    return StudentAppColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      softBackground: Color.lerp(softBackground, other.softBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      bubbleSurface: Color.lerp(bubbleSurface, other.bubbleSurface, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
    );
  }
}

class StudentThemeColors {
  final ThemeData theme;
  final StudentAppColors appColors;

  const StudentThemeColors._({
    required this.theme,
    required this.appColors,
  });

  factory StudentThemeColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final appColors =
        theme.extension<StudentAppColors>() ??
        (theme.brightness == Brightness.dark
            ? const StudentAppColors.dark()
            : const StudentAppColors.light());
    return StudentThemeColors._(theme: theme, appColors: appColors);
  }

  bool get isDark => theme.brightness == Brightness.dark;

  Color get pageBackground => theme.scaffoldBackgroundColor;

  Color get cardBackground => appColors.cardBackground;

  Color get softBackground => appColors.softBackground;

  Color get border => appColors.border;

  Color get divider => appColors.divider;

  Color get primaryText =>
      theme.textTheme.bodyLarge?.color ??
      (isDark ? Colors.white : const Color(0xFF0A2342));

  Color get secondaryText => appColors.secondaryText;

  Color get tertiaryText => appColors.tertiaryText;

  Color get icon =>
      theme.iconTheme.color ??
      (isDark ? Colors.white : const Color(0xFF101828));

  Color get shadow => appColors.shadow;

  Color get bubbleSurface => appColors.bubbleSurface;

  Color get navBackground => appColors.navBackground;
}
