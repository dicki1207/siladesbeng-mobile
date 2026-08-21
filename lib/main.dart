import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/network_wrapper.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siladesbeng_mobile/core/theme.dart';
import 'package:siladesbeng_mobile/services/firebase_messaging_service.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi locale bahasa Indonesia untuk formatting tanggal
  await initializeDateFormatting('id_ID', null);
  
  try {
    await Firebase.initializeApp();
    
    // Inisialisasi Firebase Messaging
    final fcmService = FirebaseMessagingService();
    await fcmService.initNotifications();
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');
    debugPrint('StackTrace: $stackTrace');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _getThemeMode() {
    final hour = DateTime.now().hour;
    // Mode gelap jika jam 18:00 sampai 05:59
    if (hour >= 18 || hour < 6) {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiladesBeng',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(),
      builder: (context, child) {
        return NetworkWrapper(child: child!);
      },
      // Di sini kita atur agar pertama kali buka aplikasi, munculnya Splash Screen
      home: const SplashScreen(),
    );
  }
}
