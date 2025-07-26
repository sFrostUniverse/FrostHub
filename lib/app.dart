import 'package:flutter/material.dart';
import 'package:frosthub/features/auth/presentation/screens/auth_screen.dart';

class FrostHubApp extends StatelessWidget {
  const FrostHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrostHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', // Optional
      ),
      home: const AuthScreen(),
    );
  }
}
