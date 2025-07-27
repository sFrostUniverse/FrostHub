import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      await cacheUserData(name: 'Student', email: email, role: 'student');
    } else {
      final data = doc.data();
      final name = data?['name'] ?? 'Student';
      final role = data?['role'] ?? 'student';
      await cacheUserData(name: name, email: email, role: role);
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

    await cacheUserData(name: name, email: user.email ?? '', role: 'admin');
  }

  /// Sign out user and clear local data
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears cached name/email/role
  }

  static User? get currentUser => _auth.currentUser;

  /// ✅ Cache user locally for one-tap continue
  static Future<void> cacheUserData({
    required String name,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('role', role);
  }

  /// ✅ Load cached user info
  static Future<Map<String, String?>> getCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('name'),
      'email': prefs.getString('email'),
      'role': prefs.getString('role'),
    };
  }
}
