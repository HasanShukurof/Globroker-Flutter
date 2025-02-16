import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // İzinleri iste
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM token al
    String? token = await _messaging.getToken();
    print('FCM Token: $token'); // Bu token'ı backend'e göndermeniz gerekecek

    // Local notifications için init
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Bildirime tıklandığında yapılacak işlemler
      },
    );

    // Foreground mesajları için
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Background/Terminated mesajları için
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _showNotification(RemoteMessage message) async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Yüksək Əhəmiyyətli Bildirişlər',
      importance: Importance.max,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: 'GloBroker bildirişləri',
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

// Top-level function olmalı
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background mesajları için gerekli işlemler
  print('Background message: ${message.messageId}');
}
