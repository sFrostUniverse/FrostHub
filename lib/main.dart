import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frosthub/features/timetable/presentation/screens/timetable_screen.dart';
import 'package:frosthub/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:frosthub/features/notes/presentation/screens/notes_screen.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frosthub/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:frosthub/features/group/presentation/screens/join_group_screen.dart';
import 'package:frosthub/features/main/presentation/dashboard_screen.dart';
import 'package:frosthub/features/group/presentation/screens/group_info_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final auth = FirebaseAuth.instance;
  final emailLink = Uri.base.toString();

  if (auth.isSignInWithEmailLink(emailLink)) {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email != null) {
      await AuthService.completeEmailLinkSignIn(email, emailLink);
      runApp(const FrostHubApp());
      return;
    }
  }

  runApp(const FrostHubApp());
}

class FrostHubApp extends StatelessWidget {
  const FrostHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrostHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F8FB), // Frosty white-blue
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Color.fromRGBO(255, 255, 255, 0.9),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/group-info': (context) => const GroupInfoScreen(),
        '/timetable': (context) => const TimetableScreen(),
        '/announcements': (context) => const AnnouncementsScreen(),
        '/notes': (context) => const NotesScreen(),
      },
    );
  }
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<Widget> _getHomeScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const OnboardingScreen();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      return const OnboardingScreen(); // New user → enter name + role
    }

    final data = doc.data();
    final role = data?['role'];
    final groupId = data?['groupId'];

    if (role == 'admin') {
      return const DashboardScreen(); // Admin always goes to dashboard
    }

    if (role == 'student') {
      if (groupId == null || groupId.isEmpty) {
        return const JoinGroupScreen(); // Student but no group
      } else {
        return const DashboardScreen(); // Student with group
      }
    }

    // Fallback in case of missing or invalid role
    return const OnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getHomeScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? const OnboardingScreen();
      },
    );
  }
}
