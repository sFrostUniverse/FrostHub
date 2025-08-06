import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/services/auth_service.dart';
import 'package:frosthub/features/main/presentation/screens/dashboard_screen.dart';
import 'package:frosthub/features/group/presentation/screens/group_choice_screen.dart';

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;

    final uid = googleUser.id;
    final name = googleUser.displayName ?? '';
    final email = googleUser.email;

    final response = await FrostCoreAPI.googleSignIn(
      uid: uid,
      name: name,
      email: email,
    );

    final user = response['user'];
    final token = response['token'];
    print("✅ FrostCore token: $token");

    // ✅ Fetch full profile
    final profile = await FrostCoreAPI.getUserProfile(token);
    final groupId = profile['groupId'] is String ? profile['groupId'] : '';
    final role = profile['role'] is String ? profile['role'] : '';

    print('🧪 groupId: $groupId');
    print('🧪 role: $role');

    // ✅ Save all auth data via AuthService
    final userToSave = {
      ...user,
      'groupId': groupId,
      'role': role,
    };
    await AuthService.saveAuthData(
        token, Map<String, dynamic>.from(userToSave));

    if (!context.mounted) return;

    // ✅ Navigate based on group membership
    if (groupId.isNotEmpty) {
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
  } catch (e) {
    print('❌ Sign-in error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    }
  }
}
