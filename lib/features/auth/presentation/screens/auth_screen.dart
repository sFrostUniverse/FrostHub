import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:frosthub/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:frosthub/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:frosthub/features/group/presentation/screens/group_setup_screen.dart';
import 'package:frosthub/features/group/presentation/screens/join_group_screen.dart';
import 'package:frosthub/features/main/presentation/dashboard_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // Not signed in → go to onboarding
        if (user == null) return const OnboardingScreen();

        // Signed in → check user doc
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final doc = userSnapshot.data;
            if (!doc!.exists) {
              // Firestore doc doesn't exist yet → enter name
              return const OnboardingScreen();
            }

            final data = doc.data() as Map<String, dynamic>? ?? {};
            final name = data['name'];
            final role = data['role'];
            final groupId = data['groupId'];

            // Name not set
            if (name == null || name.toString().isEmpty) {
              return const OnboardingScreen();
            }

            // Role not selected
            if (role == null || role.toString().isEmpty) {
              return RoleSelectionScreen(name: name);
            }

            // Admin with no group → create one
            if (role == 'admin' &&
                (groupId == null || groupId.toString().isEmpty)) {
              return const GroupSetupScreen(role: 'admin');
            }

            // Student with no group → join one
            if (role == 'student' &&
                (groupId == null || groupId.toString().isEmpty)) {
              return const JoinGroupScreen();
            }

            // Everything is ready → show dashboard
            return const DashboardScreen();
          },
        );
      },
    );
  }
}
