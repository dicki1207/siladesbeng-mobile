import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Ukuran desain standar (misal iPhone X/11 Pro)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'SiladesBeng',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light, // Paksa Light Mode untuk pengeditan
          builder: (context, widget) {
            final networkChild = NetworkWrapper(child: widget!);
            // Terapkan scale default ScreenUtil MediaQuery agar font tidak melenceng
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: networkChild,
            );
          },
          // Di sini kita atur agar pertama kali buka aplikasi, munculnya Splash Screen
          home: const SplashScreen(),
        );
      },
    );
  }
}
