import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:globroker/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:globroker/screens/auth_screen.dart';
import 'package:globroker/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:globroker/screens/chats_list_screen.dart';
import 'package:globroker/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:globroker/screens/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final notificationService = NotificationService();
  await notificationService.initialize();

  print('FCM TOKEN: ${await FirebaseMessaging.instance.getToken()}');

  runApp(GloBroker(
    navigatorKey: notificationService.navigatorKey,
  ));
}

class GloBroker extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const GloBroker({
    super.key,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
            return const MainScreen();
          }

          return const AuthScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    ChatsListScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Okunmamış mesaj sayısını getiren stream
  Stream<int> _getUnreadChatsCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('Messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Okunmamış bildirim sayısını getiren stream
  Stream<int> _getUnreadNotificationsCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.uid)
        .collection('Notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: StreamBuilder<int>(
          stream: _getUnreadChatsCount(),
          builder: (context, chatSnapshot) {
            final unreadChatsCount =
                chatSnapshot.hasData ? chatSnapshot.data! : 0;

            return StreamBuilder<int>(
                stream: _getUnreadNotificationsCount(),
                builder: (context, notificationSnapshot) {
                  final unreadNotificationsCount = notificationSnapshot.hasData
                      ? notificationSnapshot.data!
                      : 0;

                  return BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    currentIndex: _selectedIndex,
                    selectedItemColor: const Color(0xFF5C6BC0),
                    unselectedItemColor: Colors.grey,
                    onTap: _onItemTapped,
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Ana Səhifə',
                      ),
                      BottomNavigationBarItem(
                        icon: Stack(
                          children: [
                            const Icon(Icons.message),
                            if (unreadChatsCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Text(
                                    unreadChatsCount > 9
                                        ? '9+'
                                        : unreadChatsCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        label: 'Mesajlaşma',
                      ),
                      BottomNavigationBarItem(
                        icon: Stack(
                          children: [
                            const Icon(Icons.notifications),
                            if (unreadNotificationsCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Text(
                                    unreadNotificationsCount > 9
                                        ? '9+'
                                        : unreadNotificationsCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        label: 'Bildirimler',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Profil',
                      ),
                    ],
                  );
                });
          }),
    );
  }
}
