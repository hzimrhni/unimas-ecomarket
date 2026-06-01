import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'screens/student_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class ThemeController extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeController({
    super.key,
    required ValueNotifier<ThemeMode> notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ValueNotifier<ThemeMode> of(BuildContext context) {
    final controller =
        context.dependOnInheritedWidgetOfExactType<ThemeController>();
    assert(controller != null, 'ThemeController not found in context');
    return controller!.notifier!;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const String _themeModePrefsKey = 'student_theme_mode';
  final ValueNotifier<ThemeMode> _themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  @override
  void initState() {
    super.initState();
    _themeMode.addListener(_persistThemeMode);
    _loadSavedThemeMode();
  }

  double _responsiveTextScaleFactor(double width) {
    if (width <= 320) {
      return 0.84;
    }
    if (width <= 360) {
      return 0.9;
    }
    if (width <= 390) {
      return 0.95;
    }
    if (width <= 430) {
      return 1.0;
    }
    if (width <= 480) {
      return 1.03;
    }
    return 1.06;
  }

  ThemeData _buildTheme(Brightness brightness) {
    const primaryBlue = Color(0xFF2F6BFF);
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF101114) : const Color(0xFFF7F8FA),
      cardColor: isDark ? const Color(0xFF17191F) : Colors.white,
      dividerColor: isDark ? const Color(0x1FFFFFFF) : const Color(0xFFE5E7EB),
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : const Color(0xFF101828),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: isDark ? Colors.white : const Color(0xFF0A2342),
        displayColor: isDark ? Colors.white : const Color(0xFF0A2342),
      ),
      extensions: <ThemeExtension<dynamic>>[
        isDark
            ? const StudentAppColors.dark()
            : const StudentAppColors.light(),
      ],
    );
  }

  Future<void> _loadSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModePrefsKey);
    if (!mounted || savedMode == null) {
      return;
    }

    switch (savedMode) {
      case 'dark':
        _themeMode.value = ThemeMode.dark;
        break;
      case 'light':
      default:
        _themeMode.value = ThemeMode.light;
        break;
    }
  }

  Future<void> _persistThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = _themeMode.value == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString(_themeModePrefsKey, value);
  }

  @override
  void dispose() {
    _themeMode.removeListener(_persistThemeMode);
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      notifier: _themeMode,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeMode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'UNIMAS EcoMarket',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final width = mediaQuery.size.width;
              final scaleFactor = _responsiveTextScaleFactor(width);

              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(scaleFactor),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
