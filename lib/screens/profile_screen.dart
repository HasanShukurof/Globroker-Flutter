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
  bool _isDeletingAccount = false;
  Map<String, dynamic>? _userData;
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      // Kullanıcının Firestore verilerini silme
      final userId = _currentUser.uid;

      // Kullanıcı dokümanını silme
      await FirebaseFirestore.instance.collection('Users').doc(userId).delete();

      // Kullanıcının bildirimlerini silme
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Notifications')
          .get();

      for (var doc in notificationsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Kullanıcının mesajlarını silme
      final sentMessagesSnapshot = await FirebaseFirestore.instance
          .collection('Messages')
          .where('senderId', isEqualTo: userId)
          .get();

      for (var doc in sentMessagesSnapshot.docs) {
        await doc.reference.delete();
      }

      final receivedMessagesSnapshot = await FirebaseFirestore.instance
          .collection('Messages')
          .where('receiverId', isEqualTo: userId)
          .get();

      for (var doc in receivedMessagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Firebase Authentication'dan kullanıcıyı silme
      await _currentUser.delete();

      // Kullanıcı silindikten sonra otomatik olarak giriş ekranına yönlendirilecek
      // Bu işlem genellikle ana widget'ta dinlenen auth state değişikliği ile otomatik olarak gerçekleşir

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabınız uğurla silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      if (e.code == 'requires-recent-login') {
        // Yeniden kimlik doğrulama gerekiyor
        _showReauthenticateDialog();
      } else {
        errorMessage = 'Hesab silinərkən xəta baş verdi: ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hesab silinərkən xəta baş verdi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  void _showReauthenticateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Təhlükəsizlik doğrulaması'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hesabınızı silmək üçün şifrənizi daxil edin'),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifrə',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _passwordController.clear();
            },
            child: const Text('Ləğv et'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reauthenticateAndDeleteAccount();
            },
            child: const Text('Təsdiqlə'),
          ),
        ],
      ),
    );
  }

  Future<void> _reauthenticateAndDeleteAccount() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zəhmət olmasa şifrənizi daxil edin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      // Kullanıcının e-posta adresini al
      final email = _currentUser.email;
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-poçt ünvanı tapılmadı'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isDeletingAccount = false;
        });
        return;
      }

      // Kimlik doğrulama için kimlik bilgilerini oluştur
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _passwordController.text,
      );

      // Kullanıcıyı yeniden doğrula
      await _currentUser.reauthenticateWithCredential(credential);

      // Şifreyi temizle
      _passwordController.clear();

      // Hesabı sil
      _deleteAccount();
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      if (e.code == 'wrong-password') {
        errorMessage = 'Yanlış şifrə daxil edildi';
      } else if (e.code == 'too-many-requests') {
        errorMessage =
            'Həddindən artıq cəhd. Zəhmət olmasa bir az sonra yenidən cəhd edin';
      } else {
        errorMessage = 'Doğrulama xətası: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );

      // Şifreyi temizle
      _passwordController.clear();

      setState(() {
        _isDeletingAccount = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doğrulama xətası: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Şifreyi temizle
      _passwordController.clear();

      setState(() {
        _isDeletingAccount = false;
      });
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
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap:
                            _userData != null && _userData!['photoURL'] != null
                                ? _showProfileImage
                                : null,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _userData != null &&
                                  _userData!['photoURL'] != null
                              ? NetworkImage(_userData!['photoURL'])
                              : null,
                          child: _userData == null ||
                                  _userData!['photoURL'] == null
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
                        leading:
                            const Icon(Icons.exit_to_app, color: Colors.red),
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
                      const Divider(),
                      ListTile(
                        leading:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text(
                          'Hesabı sil',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hesabı sil'),
                              content: const Text(
                                  'Hesabınızı silmək istədiyinizə əminsiniz? Bu əməliyyat geri qaytarıla bilməz və bütün məlumatlarınız silinəcək.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Ləğv et'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteAccount();
                                  },
                                  child: const Text(
                                    'Hesabı sil',
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
                if (_isDeletingAccount)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Hesabınız silinir...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
