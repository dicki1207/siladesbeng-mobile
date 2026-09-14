import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/network_wrapper.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:siladesbeng_mobile/core/theme.dart';
import 'package:siladesbeng_mobile/services/firebase_messaging_service.dart';
import 'splash_screen.dart';

import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi locale bahasa Indonesia untuk formatting tanggal
  await initializeDateFormatting('id_ID', null);
  
  try {
    await Firebase.initializeApp();
  } catch (e, stackTrace) {
    debugPrint('Error during Firebase init: $e');
    debugPrint('StackTrace: $stackTrace');
  }
  
  runApp(const MyApp());

  // Inisialisasi FCM di background SETELAH UI sudah muncul
  // agar tidak memblokir startup jika koneksi lambat
  Future.microtask(() async {
    try {
      final fcmService = FirebaseMessagingService();
      await fcmService.initNotifications();
    } catch (e) {
      debugPrint('Error FCM init (non-blocking): $e');
    }
  });
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
