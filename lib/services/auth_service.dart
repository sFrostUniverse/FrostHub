import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send email link for student login
  static Future<void> sendSignInLink(String email) async {
    final ActionCodeSettings acs = ActionCodeSettings(
      url: 'https://frosthub-6ca1c.web.app',
      handleCodeInApp: true,
      androidPackageName: 'com.frosthub.app',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: acs);
  }

  /// Complete sign-in with email link
  static Future<void> completeEmailLinkSignIn(
      String email, String emailLink) async {
    if (!_auth.isSignInWithEmailLink(emailLink)) {
      throw Exception("Invalid or expired email link");
    }

    final userCredential =
        await _auth.signInWithEmailLink(email: email, emailLink: emailLink);
    final user = userCredential.user;
    if (user == null) throw Exception("Email sign-in failed");

    final uid = user.uid;
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Admin Google sign-in
  static Future<void> signInAsAdmin({required String name}) async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    final uid = user.uid;

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': user.email,
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;
}
