import 'package:flutter/material.dart';
import 'package:frosthub/features/auth/presentation/functions/sign_in_with_google.dart';

class GoogleSignInScreen extends StatelessWidget {
  const GoogleSignInScreen({super.key});

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
