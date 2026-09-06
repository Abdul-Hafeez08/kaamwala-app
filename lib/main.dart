import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kaamwala/views/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Quick runtime check: attempt to load the logo asset and log any error.
  try {
    await rootBundle.load('assets/logo.png');
    debugPrint('assets/logo.png loaded successfully');
  } catch (e, st) {
    debugPrint('Failed to load assets/logo.png: $e');
    if (kDebugMode) {
      // Print stack in debug mode to aid diagnosis.
      debugPrintStack(stackTrace: st);
    }
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: KaamwalaApp()));
}

class KaamwalaApp extends ConsumerWidget {
  const KaamwalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Kaamwala',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
