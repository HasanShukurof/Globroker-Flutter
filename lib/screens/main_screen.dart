import 'package:flutter/material.dart';
import 'package:globroker/screens/home_screen.dart';
import 'package:globroker/screens/chat_screen.dart';
// import 'package:globroker/screens/notifications_screen.dart'; // Dosya mevcut değil
import 'package:globroker/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const HomeScreen(),
    const ChatScreen(
        receiverId: '',
        receiverName: ''), // ChatScreen için gerekli parametreleri ekledim
    const Center(
        child: Text(
            'Bildirimler yakında!')), // NotificationsScreen yerine geçici bir widget
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Səhifə',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Mesajlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Bildirimlər',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
