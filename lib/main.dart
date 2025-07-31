import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frosthub/features/group/presentation/screens/group_chat_screen.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/screens/google_signin_screen.dart';
import 'features/group/presentation/screens/group_choice_screen.dart';
import 'features/group/presentation/screens/group_info_screen.dart';
import 'features/main/presentation/screens/dashboard_screen.dart';
import 'features/group/presentation/screens/join_group_screen.dart';
import 'package:frosthub/features/syllabus/presentation/screens/syllabus_screen.dart';
import 'features/timetable/presentation/screens/timetable_screen.dart';
import 'features/announcements/presentation/screens/announcements_screen.dart';
import 'features/notes/presentation/screens/notes_folder_screen.dart';
import 'package:frosthub/features/settings/presentation/screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:frosthub/theme/theme_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // You can log or show a local notification here
  print("🔔 Background Message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await FirebaseMessaging.instance.requestPermission();
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('🔑 FCM Token: $fcmToken');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  Widget startScreen = const GoogleSignInScreen();

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    Map<String, dynamic>? data;

    final snapshot = await userDocRef.get();
    if (!snapshot.exists) {
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
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            home: startScreen,
            routes: {
              '/timetable': (_) => const TimetableScreen(),
              '/announcements': (_) => const AnnouncementsScreen(),
              '/group-chat': (_) => const GroupChatScreen(),
              '/notes': (_) => const NotesFolderScreen(
                    parentId: null,
                    title: 'Notes',
                  ),
              '/group-info': (_) => const GroupInfoScreen(),
              '/syllabus': (_) => const SyllabusScreen(),
              '/join-group': (_) => const JoinGroupScreen(),
              '/settings': (_) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
