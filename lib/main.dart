import 'package:flutter/material.dart';
import 'package:frosthub/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart'
    as tz; // ✅ Required for timezone init
import 'services/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:frosthub/api/frostcore_api.dart';

// Screens
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/group/presentation/screens/group_chat_screen.dart';
import 'features/group/presentation/screens/group_info_screen.dart';
import 'features/group/presentation/screens/join_group_screen.dart';
import 'features/syllabus/presentation/screens/syllabus_screen.dart';
import 'features/timetable/presentation/screens/timetable_screen.dart';
import 'features/announcements/presentation/screens/announcements_screen.dart';
import 'features/notes/presentation/screens/notes_folder_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/settings/presentation/screens/about_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🕒 Schedule support for local time
  tz.initializeTimeZones();

  // 🔔 Set up local notification service
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  await Hive.openBox('cacheBox');
  await Hive.openBox('timetable_cache');
  await Hive.openBox('announcements_cache');
  await Hive.openBox(notesCacheBox);

  runApp(const FrostHubApp());
}

class FrostHubApp extends StatelessWidget {
  const FrostHubApp({super.key});

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
            home: const SplashScreen(),
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
              '/about': (_) => const AboutScreen(),
            },
          );
        },
      ),
    );
  }
}
