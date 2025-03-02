import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:globroker/screens/profile_edit_screen.dart';
import 'package:globroker/screens/profile_image_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_currentUser.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data()!;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İstifadəçi məlumatları yüklənərkən xəta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProfileImage() {
    if (_userData == null || _userData!['photoURL'] == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileImageScreen(
          imageUrl: _userData!['photoURL'],
          userName: _userData!['displayName'] ?? 'İstifadəçi',
        ),
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
    );

    // Profil düzenleme ekranından döndükten sonra verileri yeniden yükle
    _loadUserData();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Çıkış yapıldıktan sonra giriş ekranına yönlendirilecek
      // Bu işlem genellikle ana widget'ta dinlenen auth state değişikliği ile otomatik olarak gerçekleşir
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıxış zamanı xəta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _userData != null && _userData!['photoURL'] != null
                        ? _showProfileImage
                        : null,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          _userData != null && _userData!['photoURL'] != null
                              ? NetworkImage(_userData!['photoURL'])
                              : null,
                      child: _userData == null || _userData!['photoURL'] == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData != null
                        ? (_userData!['displayName'] ?? 'İstifadəçi')
                        : 'İstifadəçi',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userData != null
                        ? (_userData!['email'] ?? '')
                        : _currentUser.email ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Profili düzənlə'),
                    onTap: _navigateToEditProfile,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text(
                      'Çıxış',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Çıxış'),
                          content: const Text(
                              'Hesabınızdan çıxış etmək istədiyinizə əminsiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Ləğv et'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _signOut();
                              },
                              child: const Text(
                                'Çıxış',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
