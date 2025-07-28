import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../group/presentation/screens/group_choice_screen.dart';
import '../../../main/presentation/screens/dashboard_screen.dart';

class GoogleSignInScreen extends StatelessWidget {
  const GoogleSignInScreen({super.key});

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;
      final uid = user.uid;

      // ✅ Firestore user doc logic
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        await userDocRef.set({
          'name': user.displayName ?? '',
          'email': user.email,
          'role': 'student',
          'groupId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // ✅ Preserve groupId, just update name/email
        await userDocRef.update({
          'name': user.displayName ?? '',
          'email': user.email,
        });
      }

      // 🔍 Determine where to go based on groupId
      final latestDoc = await userDocRef.get();
      final data = latestDoc.data();

      if (context.mounted) {
        if (data != null && data['groupId'] != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GroupChoiceScreen()),
          );
        }
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Sign in with Google'),
          onPressed: () => signInWithGoogle(context),
        ),
      ),
    );
  }
}
