import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import '../screens/chat_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background mesajı alındı: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    // FCM için arka plan işleyicisini ayarla
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Bildirim izinlerini iste
    await _requestPermissions();

    // Bildirim kanallarını ayarla
    await _setupNotificationChannels();

    // Bildirim işleyicilerini ayarla
    _setupNotificationHandlers();

    // FCM token'ı al ve kaydet
    await _getFCMToken();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> _setupNotificationChannels() async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Yüksək Əhəmiyyətli Bildirişlər',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  void _setupNotificationHandlers() {
    // Foreground mesajları için
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('BILDIRIM: Foreground mesajı alındı');
      print('BILDIRIM: Başlık: ${message.notification?.title}');
      print('BILDIRIM: İçerik: ${message.notification?.body}');
      print('BILDIRIM: Data: ${message.data}');

      try {
        await _showNotification(
          title: message.notification?.title ?? '',
          body: message.notification?.body ?? '',
          payload: message.data.toString(),
        );
        print('BILDIRIM: Bildirim başarıyla gösterildi');
      } catch (e) {
        print('BILDIRIM HATASI: Bildirim gösterilirken hata: $e');
      }
    });

    // Uygulama arka plandayken tıklanan bildirimler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Background mesajları için
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _handleNotificationTap(NotificationResponse response) {
    // Bildirime tıklandığında sohbet ekranına yönlendir
    final data = response.payload?.split(',');
    if (data != null && data.length >= 2) {
      final senderId = data[0];
      final senderName = data[1];
      _navigateToChatScreen(senderId, senderName);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final senderId = message.data['senderId'];
    final senderName = message.data['senderName'];
    if (senderId != null && senderName != null) {
      _navigateToChatScreen(senderId, senderName);
    }
  }

  void _navigateToChatScreen(String senderId, String senderName) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: senderId,
          receiverName: senderName,
        ),
      ),
    );
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      print('FCM TOKEN: $token');

      if (token != null) {
        await _saveFCMToken(token);
        print('FCM TOKEN: Token başarıyla kaydedildi');
      }
    } catch (e) {
      print('FCM TOKEN HATASI: Token alınırken hata: $e');
    }

    // Token yenilendiğinde
    _messaging.onTokenRefresh.listen(_saveFCMToken);
  }

  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'high_importance_channel',
          'Yüksək Əhəmiyyətli Bildirişlər',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );

    // Badge sayısını güncelle
    await updateBadgeCount(FirebaseAuth.instance.currentUser!.uid);
  }

  Future<void> updateBadgeCount(String currentUserId) async {
    final unreadMessages = await FirebaseFirestore.instance
        .collection('Messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final senderIds = unreadMessages.docs
        .map((doc) => doc.data()['senderId'] as String)
        .toSet();

    await FlutterAppBadger.updateBadgeCount(senderIds.length);
  }
}
