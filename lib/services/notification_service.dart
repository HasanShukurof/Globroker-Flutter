import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/chat_screen.dart';

// Son bildirimin ID'sini ve zamanını global olarak takip etmek için
String? _lastBackgroundMessageId;
DateTime? _lastBackgroundMessageTime;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Aynı mesajı kontrol et
  final messageId = message.messageId;
  final currentTime = DateTime.now();

  // Aynı ID'ye sahip mesaj veya son 2 saniye içinde gelen mesaj kontrolü
  if (messageId == _lastBackgroundMessageId ||
      (_lastBackgroundMessageTime != null &&
          currentTime.difference(_lastBackgroundMessageTime!).inSeconds < 2)) {
    print('BACKGROUND BILDIRIM: Tekrarlanan bildirim engellendi');
    return; // Aynı mesajı tekrar gösterme
  }

  _lastBackgroundMessageId = messageId;
  _lastBackgroundMessageTime = currentTime;

  // Background bildirimlerini göstermek için NotificationService'i başlat
  final notificationService = NotificationService();
  await notificationService._setupNotificationChannels();

  await notificationService._showNotification(
    title: message.notification?.title ?? 'Yeni Mesaj',
    body: message.notification?.body ?? '',
    payload: '${message.data['senderId']},${message.data['senderName']}',
  );
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    // iOS için ek ayarlar
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

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
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isIOS) {
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

    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  void _setupNotificationHandlers() {
    // Son bildirimin ID'sini takip etmek için
    String? lastMessageId;
    DateTime? lastMessageTime;

    // Foreground mesajları için
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Aynı mesajı kontrol et
      final messageId = message.messageId;
      final currentTime = DateTime.now();

      // Aynı ID'ye sahip mesaj veya son 2 saniye içinde gelen mesaj kontrolü
      if (messageId == lastMessageId ||
          (lastMessageTime != null &&
              currentTime.difference(lastMessageTime!).inSeconds < 2)) {
        print('BILDIRIM: Tekrarlanan bildirim engellendi');
        return; // Aynı mesajı tekrar gösterme
      }

      lastMessageId = messageId;
      lastMessageTime = currentTime;

      print('BILDIRIM: Foreground mesajı alındı');
      print('BILDIRIM: Başlık: ${message.notification?.title}');
      print('BILDIRIM: İçerik: ${message.notification?.body}');
      print('BILDIRIM: Data: ${message.data}');

      // Her mesaj için bildirim göster
      if (message.notification != null) {
        await _showNotification(
          title: message.notification!.title ?? 'Yeni Mesaj',
          body: message.notification!.body ?? '',
          payload: '${message.data['senderId']},${message.data['senderName']}',
        );
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
      try {
        // Önce kullanıcı belgesini kontrol et
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Kullanıcı belgesi varsa güncelle
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .update({'fcmToken': token});
          print('FCM TOKEN: Token güncellendi - ${user.uid}');
        } else {
          // Kullanıcı belgesi yoksa oluştur
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .set({
            'fcmToken': token,
            'displayName': user.displayName ?? 'İsimsiz Kullanıcı',
            'email': user.email,
            'photoURL': user.photoURL,
            'uid': user.uid,
          });
          print('FCM TOKEN: Yeni kullanıcı belgesi oluşturuldu - ${user.uid}');
        }

        // Kontrol amaçlı token'ı tekrar oku
        final updatedDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        print('FCM TOKEN KONTROL: ${updatedDoc.data()?['fcmToken']}');
      } catch (e) {
        print('FCM TOKEN KAYIT HATASI: $e');
      }
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Benzersiz bir bildirim ID'si oluştur
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    await _localNotifications.show(
      notificationId, // Daha güvenilir bir ID
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Yüksək Əhəmiyyətli Bildirişlər',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
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
    // Şimdilik sadece okunmamış mesajları sayalım
    final unreadMessages = await FirebaseFirestore.instance
        .collection('Messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final senderIds = unreadMessages.docs
        .map((doc) => doc.data()['senderId'] as String)
        .toSet();

    // Badge güncelleme kodunu kaldır
    // await FlutterAppBadger.updateBadgeCount(senderIds.length);
  }
}
