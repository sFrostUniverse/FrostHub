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
      try {
        await AuthService.completeEmailLinkSignIn(email, emailLink);
      } catch (e) {
        debugPrint("Email link sign-in failed: $e");
      }
    } else {
      debugPrint("No email cached for link sign-in.");
    }
  }

  runApp(const FrostHubApp()); // ✅ Always call runApp
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
        scaffoldBackgroundColor: const Color(0xFFF4F8FB),
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

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String? _cachedName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final cachedData = await AuthService.getCachedUserData();
    setState(() {
      _cachedName = cachedData['name'];
      _isLoading = false;
    });
  }

  void _continueAsUser() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<Widget> _getHomeScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const OnboardingScreen();

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return const OnboardingScreen();

    final data = doc.data();
    final role = data?['role'];
    final groupId = data?['groupId'];

    if (role == 'admin') return const DashboardScreen();
    if (role == 'student') {
      if (groupId == null || groupId.isEmpty) {
        return const JoinGroupScreen();
      } else {
        return const DashboardScreen();
      }
    }

    return const OnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _cachedName != null && FirebaseAuth.instance.currentUser == null
        ? Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Welcome Back!",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Continue as $_cachedName",
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _continueAsUser,
                      child: const Text("Continue"),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        AuthService.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OnboardingScreen()),
                        );
                      },
                      child: const Text("Not you? Switch account"),
                    ),
                  ],
                ),
              ),
            ),
          )
        : FutureBuilder<Widget>(
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
