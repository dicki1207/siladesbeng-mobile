import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// Top-level handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // 1. Minta Izin Notifikasi (terutama iOS, atau Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Konfigurasi Local Notifications (untuk Foreground)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(settings: initSettings);

    // Bikin channel notifikasi khusus Android supaya bunyi & pop-up
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Listener saat aplikasi sedang dibuka (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message, channel);
      }
    });

    // 4. Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Ambil FCM Token dan kirim ke server
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint("FCM Token: $token");
      await updateTokenToServer(token);
    }

    // 6. Listen if token changes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      updateTokenToServer(newToken);
    });
  }

  void _showLocalNotification(
      RemoteMessage message, AndroidNotificationChannel channel) {
    _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
  }

  static Future<void> updateTokenToServer(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      // Jika belum login, tidak usah dikirim
      if (token == null) return;

      final res = await http.post(
        Uri.parse('http://10.193.206.148:8000/api/fcm-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'fcm_token': fcmToken,
        },
      );

      if (res.statusCode == 200) {
        debugPrint('Berhasil update FCM Token ke server');
      } else {
        debugPrint('Gagal update FCM Token: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error kirim FCM token: $e');
    }
  }
}
