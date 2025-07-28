import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'features/auth/presentation/screens/google_signin_screen.dart';
import 'features/group/presentation/screens/group_choice_screen.dart';
import 'package:frosthub/features/group/presentation/screens/group_info_screen.dart';
import 'features/main/presentation/screens/dashboard_screen.dart';
import 'package:frosthub/features/group/presentation/screens/join_group_screen.dart';

import 'features/timetable/presentation/screens/timetable_screen.dart';
import 'features/announcements/presentation/screens/announcements_screen.dart';
import 'features/notes/presentation/screens/notes_folder_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Widget startScreen = const GoogleSignInScreen();

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    Map<String, dynamic>? data;

    final snapshot = await userDocRef.get();
    if (!snapshot.exists) {
      // User doc doesn't exist – create it
      await userDocRef.set({
        'name': user.displayName ?? '',
        'email': user.email,
        'role': 'student',
        'groupId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      data = {
        'role': 'student',
        'groupId': null,
      };
    } else {
      data = snapshot.data();
    }

    if (data != null && data['groupId'] != null) {
      startScreen = const DashboardScreen();
    } else {
      startScreen = const GroupChoiceScreen();
    }
  }

  runApp(FrostHubApp(startScreen: startScreen));
}

class FrostHubApp extends StatelessWidget {
  final Widget startScreen;

  const FrostHubApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrostHub',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: startScreen,
      routes: {
        '/': (_) => const GoogleSignInScreen(),
        '/timetable': (_) => const TimetableScreen(),
        '/announcements': (_) => const AnnouncementsScreen(),
        '/notes': (_) => NotesFolderScreen(
              parentId: null,
              title: 'Notes',
            ),
        '/group-info': (_) => const GroupInfoScreen(),
        '/join-group': (_) => const JoinGroupScreen(), // ✅ Add this line
      },
    );
  }
}
