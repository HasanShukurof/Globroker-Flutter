import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:globroker/services/auth_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  Future<void> _saveUserToFirestore(User user, {String? displayName}) async {
    try {
      print('Firestore kayıt başlıyor...');
      final userDoc =
          FirebaseFirestore.instance.collection('Users').doc(user.uid);

      // Mevcut kullanıcı verilerini kontrol et
      final userSnapshot = await userDoc.get();
      String finalDisplayName = displayName ?? user.displayName ?? 'İstifadəçi';

      // Varsayılan profil resmi URL'si
      const String defaultAvatarUrl =
          'https://ui-avatars.com/api/?background=random&color=ffffff&name=';

      // Apple ile giriş yapan kullanıcılar için özel kontrol
      if (user.providerData
          .any((provider) => provider.providerId == 'apple.com')) {
        if (userSnapshot.exists) {
          // Eğer kullanıcı daha önce kayıtlıysa ve displayName varsa, onu koru
          final existingData = userSnapshot.data() as Map<String, dynamic>;
          if (existingData['displayName'] != null &&
              existingData['displayName'] != 'İstifadəçi') {
            finalDisplayName = existingData['displayName'];
          }
        }
      }

      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': finalDisplayName,
        'createdAt': userSnapshot.exists
            ? userSnapshot.get('createdAt')
            : FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'photoURL': user.photoURL ??
            '$defaultAvatarUrl${Uri.encodeComponent(finalDisplayName)}',
      };

      print('Kaydedilecek veri: $userData');
      await userDoc.set(userData);
      print('Firestore kayıt başarılı!');
    } catch (e) {
      print('Firestore kayıt hatası: $e');
      // Hata durumunda kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı bilgileri kaydedilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Google Sign In başlatılıyor...');
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('Kullanıcı hesap seçimini iptal etti');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Kullanıcıyı Firestore'a kaydet
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }
    } catch (e) {
      String message = 'Google ilə giriş zamanı xəta baş verdi';
      if (e is FirebaseAuthException) {
        message =
            'Google hesabı ilə giriş uğursuz oldu. Zəhmət olmasa yenidən cəhd edin';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEmailAuth() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Giriş yapan kullanıcının son giriş zamanını güncelle
        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userCredential.user!.uid)
              .update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      } else {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await userCredential.user
            ?.updateDisplayName(_nameController.text.trim());

        // Yeni kullanıcıyı Firestore'a kaydet
        if (userCredential.user != null) {
          await _saveUserToFirestore(
            userCredential.user!,
            displayName: _nameController.text.trim(),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message =
              'Bu email ünvanı ilə artıq qeydiyyatdan keçilib. Zəhmət olmasa daxil olun';
        case 'invalid-email':
          message = 'Email ünvanını düzgün formatda daxil edin';
        case 'user-disabled':
          message = 'Bu hesab bloklanıb. Dəstək xidməti ilə əlaqə saxlayın';
        case 'user-not-found':
          message =
              'Bu email ünvanı ilə hesab tapılmadı. Zəhmət olmasa qeydiyyatdan keçin';
        case 'wrong-password':
          message = 'Email və ya şifrəni doğru qeyd edin';
        case 'weak-password':
          message =
              'Şifrə çox zəifdir. Ən azı 6 simvol, hərf və rəqəm istifadə edin';
        case 'operation-not-allowed':
          message =
              'Email və şifrə ilə giriş aktiv deyil. Google ilə daxil olmağı sınayın';
        case 'too-many-requests':
          message =
              'Çox sayda uğursuz cəhd. 5 dəqiqə gözləyib yenidən cəhd edin';
        default:
          message =
              'Giriş zamanı xəta baş verdi. Məlumatları yoxlayıb yenidən cəhd edin';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithApple();

      if (userCredential?.user != null) {
        await _saveUserToFirestore(userCredential!.user!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Apple ilə giriş zamanı xəta baş verdi'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPasswordRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Şifrə tələbləri',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Şifrəniz aşağıdakı tələblərə cavab verməlidir:'),
            SizedBox(height: 12),
            Text('• Ən azı 6 simvol'),
            Text('• Ən azı 1 böyük hərf (A-Z)'),
            Text('• Ən azı 1 rəqəm (0-9)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  _isLogin ? 'Daxil ol' : 'Qeydiyyat',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (!_isLogin)
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Ad Soyad',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Zəhmət olmasa adınızı daxil edin';
                      }
                      return null;
                    },
                  ),
                if (!_isLogin) const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email ünvanını daxil edin';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Düzgün email formatı daxil edin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onTap: () {
                    setState(() {});
                  },
                  onEditingComplete: () {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    labelText: 'Şifrə',
                    hintText: '******',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifrəni daxil edin';
                    }

                    List<String> errors = [];

                    if (value.length < 6) {
                      errors.add('6 simvoldan az');
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      errors.add('böyük hərf yoxdur');
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      errors.add('rəqəm yoxdur');
                    }

                    if (errors.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showPasswordRulesDialog();
                      });
                      return 'Şifrə tələblərə uyğun deyil: ${errors.join(', ')}';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? 'Daxil ol' : 'Qeydiyyatdan keç',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Hesabınız yoxdur? Qeydiyyatdan keçin'
                        : 'Hesabınız var? Daxil olun',
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('və ya'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/images/google_icon.png',
                    height: 24,
                  ),
                  label: const Text('Google ilə daxil ol'),
                ),
                if (Platform.isIOS)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SignInWithAppleButton(
                      onPressed: _handleAppleSignIn,
                      style: SignInWithAppleButtonStyle.black,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
