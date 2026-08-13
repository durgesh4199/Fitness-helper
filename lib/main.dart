import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/auth_provider.dart';
import 'providers/body_measurement_provider.dart';
import 'providers/food_catalog_provider.dart';
import 'providers/health_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/strength_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/weight_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite only ships native implementations for Android/iOS/macOS. When
  // this app is run on Windows/Linux (desktop) during development, fall
  // back to the FFI-backed implementation instead.
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Firebase (sign-in + cloud backup) needs a real google-services.json —
  // see docs/FIREBASE_SETUP.md. Without one this simply fails to init;
  // AppAuthProvider itself catches that and reports unavailable (see its
  // doc comment), so the rest of the app still works exactly as before,
  // fully local and with no sign-in gate, instead of crashing.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Handled by AppAuthProvider.isAvailable — nothing to do here.
  }

  await NotificationService.instance.init();

  runApp(const FitnessTrackerApp());
}

class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()..load()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()..load()),
        ChangeNotifierProvider(create: (_) => StrengthProvider()..load()),
        ChangeNotifierProvider(create: (_) => WeightProvider()..load()),
        ChangeNotifierProvider(create: (_) => BodyMeasurementProvider()..load()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()..load()),
        ChangeNotifierProvider(create: (_) => FoodCatalogProvider()..load()),
        ChangeNotifierProvider(create: (_) => HealthProvider()..init()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Fitness Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Gates the rest of the app behind a signed-in Firebase user — but only
/// when Firebase is actually configured (see [AppAuthProvider.isAvailable]).
/// Without real config (including today's widget tests, which never
/// initialize Firebase), this transparently falls through to the app's
/// original onboarding/home flow instead of blocking on a sign-in screen
/// that could never succeed.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    if (!auth.isAvailable) return const _AppRoot();
    return auth.isSignedIn ? const _AppRoot() : const AuthScreen();
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.loading) {
          return Scaffold(
            backgroundColor: colors.background,
            body: Center(child: CircularProgressIndicator(color: colors.primary)),
          );
        }
        return userProvider.onboardingComplete ? const MainShell() : const OnboardingScreen();
      },
    );
  }
}
