import 'package:flutter/material.dart';
// Import the WelcomeScreen
import 'features/auth/presentation/screens/welcome_screen.dart'; 

void main() {
  runApp(const DermatechApp());
}

/// Root widget of the application.
class DermatechApp extends StatelessWidget {
  const DermatechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dermatech Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A2342)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      // Set the initial route to WelcomeScreen
      home: const WelcomeScreen(),
    );
  }
}