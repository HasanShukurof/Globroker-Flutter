import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/chat_screen.dart';

// Bildirim servisi - Singleton pattern kullanıyoruz
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Son bildirim bilgilerini takip etmek için değişkenler
  String? _lastMessageId;
  DateTime? _lastMessageTime;
  Map<String, DateTime> _lastSenderNotifications = {};

  // Bildirim kanalı ID'si
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'Yüksək Əhəmiyyətli Bildirişlər';

  // Bildirim servisini başlat
  Future<void> initialize() async {
    try {
      print('BILDIRIM SERVISI: Başlatılıyor...');

      // iOS için ek ayarlar
      if (Platform.isIOS) {
        print('BILDIRIM SERVISI: iOS ayarları yapılandırılıyor...');
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('BILDIRIM SERVISI: iOS ayarları tamamlandı');
      }

      // Bildirim izinlerini iste
      print('BILDIRIM SERVISI: Bildirim izinleri isteniyor...');
      await _requestPermissions();
      print('BILDIRIM SERVISI: Bildirim izinleri alındı');

      // Bildirim kanallarını ayarla
      print('BILDIRIM SERVISI: Bildirim kanalları ayarlanıyor...');
      await _setupNotificationChannels();
      print('BILDIRIM SERVISI: Bildirim kanalları ayarlandı');

      // ÖNEMLİ: Foreground mesajları için dinleyici ayarla
      // Bu, uygulamanın ön planda olduğu durumda bildirimleri işleyecek
      print('BILDIRIM SERVISI: Foreground mesaj dinleyicisi ayarlanıyor...');
      _setupForegroundMessageHandler();
      print('BILDIRIM SERVISI: Foreground mesaj dinleyicisi ayarlandı');

      // Bildirime tıklama işleyicisini ayarla
      print('BILDIRIM SERVISI: Bildirim tıklama işleyicisi ayarlanıyor...');
      _setupNotificationTapHandler();
      print('BILDIRIM SERVISI: Bildirim tıklama işleyicisi ayarlandı');

      // FCM token'ı al ve kaydet
      print('BILDIRIM SERVISI: FCM token alınıyor...');
      await _getFCMToken();
      print('BILDIRIM SERVISI: FCM token alındı ve kaydedildi');

      print('BILDIRIM SERVISI: Başarıyla başlatıldı');
    } catch (e) {
      print('BILDIRIM SERVISI HATASI: $e');
    }
  }

  // Bildirim izinlerini iste
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

  // Bildirim kanallarını ayarla
  Future<void> _setupNotificationChannels() async {
    // Android için bildirim kanalı oluştur
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // iOS ve Android için bildirim ayarları
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

    // Bildirim tıklama işleyicisini ayarla
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  // Foreground mesajları için dinleyici
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        print('FOREGROUND BILDIRIM: Bildirim alındı');
        print('FOREGROUND BILDIRIM: ID: ${message.messageId}');
        print('FOREGROUND BILDIRIM: Başlık: ${message.notification?.title}');
        print('FOREGROUND BILDIRIM: İçerik: ${message.notification?.body}');
        print('FOREGROUND BILDIRIM: Data: ${message.data}');

        // Bildirim filtreleme - Aynı bildirimi tekrar gösterme
        if (!_shouldShowNotification(message)) {
          print('FOREGROUND BILDIRIM: Bildirim filtrelendi, gösterilmeyecek');
          return;
        }

        // Bildirimi Firestore'a kaydet (mesaj bildirimleri hariç)
        if (!_isMessageNotification(message)) {
          await _saveNotificationToFirestore(message);
        }

        // Bildirim verisi hazırlama
        final notificationData = _prepareNotificationData(message);

        // Bildirimi göster
        await _showNotification(
          title: notificationData.title,
          body: notificationData.body,
          payload: notificationData.payload,
          groupKey: notificationData.groupKey,
        );

        print('FOREGROUND BILDIRIM: Bildirim gösterildi');
      } catch (e) {
        print('FOREGROUND BILDIRIM HATASI: $e');
      }
    });
  }

  // Bildirime tıklama işleyicisini ayarla
  void _setupNotificationTapHandler() {
    // Uygulama arka plandayken tıklanan bildirimler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Bildirime tıklandığında çağrılacak metod
  void _handleNotificationTap(NotificationResponse response) {
    try {
      print('BILDIRIM TAP: Bildirime tıklandı, payload: ${response.payload}');

      // Payload'ı işle
      final data = response.payload?.split(',');
      if (data != null && data.length >= 2) {
        final senderId = data[0];
        final senderName = data[1];

        // Boş değilse sohbet ekranına yönlendir
        if (senderId.isNotEmpty && senderName.isNotEmpty) {
          _navigateToChatScreen(senderId, senderName);
        }
      }
    } catch (e) {
      print('BILDIRIM TAP HATASI: $e');
    }
  }

  // Uygulama arka plandayken bildirime tıklandığında çağrılacak metod
  void _handleMessageOpenedApp(RemoteMessage message) {
    try {
      print('BILDIRIM OPENED APP: Bildirime tıklandı');

      final senderId = message.data['senderId'];
      final senderName = message.data['senderName'];

      if (senderId != null && senderName != null) {
        _navigateToChatScreen(senderId, senderName);
      }
    } catch (e) {
      print('BILDIRIM OPENED APP HATASI: $e');
    }
  }

  // Sohbet ekranına yönlendirme
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

  // FCM token'ı al ve kaydet
  Future<void> _getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      print('FCM TOKEN: $token');

      if (token != null) {
        await _saveFCMToken(token);
      }

      // Token yenilendiğinde
      _messaging.onTokenRefresh.listen(_saveFCMToken);
    } catch (e) {
      print('FCM TOKEN HATASI: $e');
    }
  }

  // FCM token'ı Firestore'a kaydet
  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Kullanıcı belgesini kontrol et
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
        }
      } catch (e) {
        print('FCM TOKEN KAYIT HATASI: $e');
      }
    }
  }

  // Bildirimin gösterilip gösterilmeyeceğine karar veren metod
  bool _shouldShowNotification(RemoteMessage message) {
    final messageId = message.messageId;
    final currentTime = DateTime.now();

    // Aynı ID'ye sahip mesaj kontrolü
    if (messageId == _lastMessageId) {
      print('BILDIRIM FILTRE: Aynı ID\'ye sahip bildirim engellendi');
      return false;
    }

    // Son 2 saniye içinde gelen bildirim kontrolü
    if (_lastMessageTime != null &&
        currentTime.difference(_lastMessageTime!).inSeconds < 2) {
      print('BILDIRIM FILTRE: Son 2 saniye içinde bildirim geldi, engellendi');
      return false;
    }

    // Aynı gönderenden son 10 saniye içinde bildirim gelmiş mi kontrolü
    final senderId = message.data['senderId'];
    if (senderId != null && _lastSenderNotifications.containsKey(senderId)) {
      final lastTime = _lastSenderNotifications[senderId]!;
      if (currentTime.difference(lastTime).inSeconds < 10) {
        print(
            'BILDIRIM FILTRE: Aynı gönderenden son 10 saniye içinde bildirim geldi, engellendi');
        return false;
      }
    }

    // Bildirimin gösterilmesine izin veriliyorsa, son bildirim bilgilerini güncelle
    _lastMessageId = messageId;
    _lastMessageTime = currentTime;

    // Gönderici ID'si varsa, son bildirim zamanını güncelle
    if (senderId != null) {
      _lastSenderNotifications[senderId] = currentTime;
    }

    return true; // Bildirimin gösterilmesine izin ver
  }

  // Mesaj bildirimi mi kontrolü
  bool _isMessageNotification(RemoteMessage message) {
    return message.data.containsKey('senderId') &&
        message.data.containsKey('senderName');
  }

  // Bildirim verilerini hazırlama
  _NotificationData _prepareNotificationData(RemoteMessage message) {
    String title = message.notification?.title ?? 'Yeni Mesaj';
    String body = message.notification?.body ?? '';
    String? groupKey;
    String payload = '';

    // Mesaj bildirimi ise
    if (_isMessageNotification(message)) {
      final senderId = message.data['senderId'];
      final senderName = message.data['senderName'];

      // Eğer notification verisi yoksa ve bu bir mesaj bildirimi ise
      if (message.notification == null && message.data.containsKey('content')) {
        title = 'Yeni Mesaj';
        body = '${senderName}: ${message.data['content']}';
      }

      // Payload ve groupKey ayarla
      payload = '$senderId,$senderName';
      groupKey = senderId != null ? 'message_$senderId' : null;
    }

    return _NotificationData(
      title: title,
      body: body,
      payload: payload,
      groupKey: groupKey,
    );
  }

  // Bildirimi Firestore'a kaydetme
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Mesaj bildirimleri için kontrol
      if (_isMessageNotification(message)) {
        print('BILDIRIM KAYIT: Mesaj bildirimi olduğu için kaydedilmedi');
        return;
      }

      // Konsol bildirimlerini tespit et
      bool isFromConsole = message.data.containsKey('google.c.sender.id') ||
          message.data.containsKey('google.c.a.e');

      // Bildirim verilerini hazırla
      Map<String, dynamic> notificationData = {
        'title': message.notification?.title ?? 'Yeni Bildirim',
        'body': message.notification?.body ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'source': isFromConsole ? 'console' : 'direct',
      };

      // Data alanını filtrele (google.* alanlarını kaldır)
      Map<String, dynamic> filteredData = {};
      message.data.forEach((key, value) {
        if (!key.startsWith('google.')) {
          filteredData[key] = value;
        }
      });

      if (filteredData.isNotEmpty) {
        notificationData['data'] = filteredData;
      }

      // Firestore'a kaydet
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Notifications')
          .add(notificationData);

      print('BILDIRIM KAYIT: Firestore\'a kaydedildi');
    } catch (e) {
      print('BILDIRIM KAYIT HATASI: $e');
    }
  }

  // Bildirimi gösterme
  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
    String? groupKey,
  }) async {
    try {
      // Bildirim ID'si oluştur
      final int notificationId;

      // Mesaj bildirimleri için sabit ID kullan
      if (groupKey != null && groupKey.startsWith('message_')) {
        notificationId = groupKey.hashCode % 100000;
      } else {
        // Diğer bildirimler için içerik bazlı ID
        final contentHash = '$title$body'.hashCode;
        notificationId =
            (DateTime.now().millisecondsSinceEpoch + contentHash) % 100000;
      }

      print(
          'BILDIRIM GOSTERME: ID=$notificationId, Başlık=$title, İçerik=$body');

      // Bildirimi göster
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            groupKey: groupKey,
            channelShowBadge: true,
            autoCancel: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );

      print('BILDIRIM GOSTERME: Başarılı');
    } catch (e) {
      print('BILDIRIM GOSTERME HATASI: $e');
    }
  }

  // Bildirimleri okundu olarak işaretleme
  Future<void> markNotificationAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('BILDIRIM GUNCELLEME HATASI: $e');
    }
  }

  // Tüm bildirimleri okundu olarak işaretleme
  Future<void> markAllNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('TUM BILDIRIMLERI GUNCELLEME HATASI: $e');
    }
  }

  // Badge sayısını güncelleme
  Future<void> updateBadgeCount(String userId) async {
    try {
      // Okunmamış mesajları say
      final unreadMessages = await FirebaseFirestore.instance
          .collection('Messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final senderIds = unreadMessages.docs
          .map((doc) => doc.data()['senderId'] as String)
          .toSet();

      // Badge güncelleme kodunu kaldır
      // await FlutterAppBadger.updateBadgeCount(senderIds.length);
    } catch (e) {
      print('BADGE GUNCELLEME HATASI: $e');
    }
  }
}

// Bildirim verilerini taşıyan yardımcı sınıf
class _NotificationData {
  final String title;
  final String body;
  final String payload;
  final String? groupKey;

  _NotificationData({
    required this.title,
    required this.body,
    this.payload = '',
    this.groupKey,
  });
}
