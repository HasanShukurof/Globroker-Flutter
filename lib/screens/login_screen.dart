import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Google Sign In başlatılıyor...');
      final GoogleSignIn googleSignIn = GoogleSignIn();

      print('Önceki oturum temizleniyor...');
      await googleSignIn.signOut();

      print('Google hesap seçimi açılıyor...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('Kullanıcı hesap seçimini iptal etti');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      print('Google kimlik doğrulama alınıyor...');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('Firebase kimlik bilgileri oluşturuluyor...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Firebase ile giriş yapılıyor...');
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Kullanıcı girişi başarısız');
      }

      print('Giriş başarılı: ${userCredential.user?.email}');
    } catch (e, stackTrace) {
      print('HATA: $e');
      print('Stack Trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş zamanı xəta baş verdi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        print('Hata sonrası oturum temizleniyor...');
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/globicon.png',
                height: 120,
              ),
              const SizedBox(height: 48),
              const Text(
                'GloBroker',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/google_icon.png',
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Google ilə daxil ol',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
