import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _firebaseAuth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final _firestore = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  // Get user email
  String getUserEmail() => _firebaseAuth.currentUser?.email ?? "User";

  // Apple login method
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String displayName =
          '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim();
      final String finalDisplayName = displayName.isNotEmpty
          ? displayName
          : (appleCredential.email?.split('@')[0] ?? 'İstifadəçi');

      final oAuthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oAuthCredential);

      // Kullanıcı adını hem Firebase Auth hem de Firestore'a kaydet
      if (userCredential.user != null) {
        await userCredential.user?.updateDisplayName(finalDisplayName);

        // Firestore'a kaydet
        await _firestore.collection('Users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'displayName': finalDisplayName,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'photoURL': userCredential.user!.photoURL ??
              'https://ui-avatars.com/api/?background=random&color=ffffff&name=${Uri.encodeComponent(finalDisplayName)}',
        }, SetOptions(merge: true));
      }

      return userCredential;
    } catch (e) {
      print("Error during Sign in with Apple: $e");
      return null;
    }
  }

  // Apple ile yeniden kimlik doğrulama
  Future<UserCredential?> reauthenticateWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
        ],
      );

      final oAuthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _firebaseAuth.currentUser
          ?.reauthenticateWithCredential(oAuthCredential);
    } catch (e) {
      print("Error during Apple reauthentication: $e");
      return null;
    }
  }

  // Google ile yeniden kimlik doğrulama
  Future<UserCredential?> reauthenticateWithGoogle() async {
    try {
      // Mevcut Google oturumunu kapat
      await _googleSignIn.signOut();

      // Yeni Google oturumu aç
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.currentUser
          ?.reauthenticateWithCredential(credential);
    } catch (e) {
      print("Error during Google reauthentication: $e");
      return null;
    }
  }
}
