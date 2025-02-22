import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import '../screens/chat_screen.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // İzinleri iste
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Foreground mesajları için
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Foreground mesajı alındı: ${message.notification?.title}');

      await _showNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    });

    // Background mesajları için
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // FCM token al
    if (Platform.isIOS) {
      // iOS için önce APNS token'ı al
      String? apnsToken = await _messaging.getAPNSToken();
      print('APNS Token: $apnsToken');

      if (apnsToken != null) {
        String? fcmToken = await _messaging.getToken();
        print('iOS FCM Token: $fcmToken');
      }
    } else {
      // Android için direkt FCM token'ı al
      String? fcmToken = await _messaging.getToken();
      print('Android FCM Token: $fcmToken');
    }

    // Local notifications için init
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Bildirime tıklandığında yapılacak işlemler
        print('Bildirime tıklandı: ${details.payload}');
      },
    );

    // Bildirime tıklanınca
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final senderId = message.data['senderId'] as String?;
      final senderName = message.data['senderName'] as String?;

      if (senderId != null && senderName != null) {
        // Sohbet ekranına yönlendir
        Navigator.of(GlobalKey<NavigatorState>().currentContext!).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              receiverId: senderId,
              receiverName: senderName,
            ),
          ),
        );
      }
    });
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Yüksək Əhəmiyyətli Bildirişlər',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: 'GloBroker bildirişləri',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await updateBadgeCount(currentUser.uid);
    }
  }

  // Badge sayısını güncelle
  Future<void> updateBadgeCount(String currentUserId) async {
    final unreadMessages = await FirebaseFirestore.instance
        .collection('Messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    // Benzersiz gönderici sayısını hesapla
    final senderIds = unreadMessages.docs
        .map((doc) => doc.data()['senderId'] as String)
        .toSet();

    // Badge sayısını güncelle
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(badge: true);
    }

    await FlutterAppBadger.updateBadgeCount(senderIds.length);
  }
}

// Top-level function olmalı
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background mesajları için gerekli işlemler
  print('Background message: ${message.messageId}');
}
