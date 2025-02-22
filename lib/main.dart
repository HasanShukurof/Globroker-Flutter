import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:globroker/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:globroker/screens/auth_screen.dart';
import 'package:globroker/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM token'ı al ve kaydet
  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    _saveFcmToken(token);
  });

  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await _saveFcmToken(token);
  }

  // Firestore ayarları
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Notification servisini başlat
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const GloBroker());
}

Future<void> _saveFcmToken(String token) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .update({'fcmToken': token});
  }
}

class GloBroker extends StatefulWidget {
  const GloBroker({super.key});

  @override
  State<GloBroker> createState() => _GloBrokerState();
}

class _GloBrokerState extends State<GloBroker> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('az', 'AZ'),
      ],
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Xəta baş verdi: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }

          return const AuthScreen();
        },
      ),
    );
  }
}
