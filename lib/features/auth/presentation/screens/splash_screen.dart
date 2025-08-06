import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/api/frostcore_api.dart';
import 'package:frosthub/features/main/presentation/screens/dashboard_screen.dart';
import 'package:frosthub/features/auth/presentation/screens/google_signin_screen.dart';
import 'package:frosthub/features/group/presentation/screens/group_choice_screen.dart'; // Add this import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _goToLogin();
      return;
    }

    try {
      final profile = await FrostCoreAPI.getUserProfile(token);
      final groupId = profile['groupId'];

      if (!mounted) return;

      if (groupId != null && groupId.isNotEmpty) {
        // ✅ User has joined/created a group
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        // ✅ User is logged in but hasn't joined/created a group
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GroupChoiceScreen()),
        );
      }
    } catch (e) {
      // ❌ Token was invalid or request failed
      await prefs.clear();
      if (!mounted) return;
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
