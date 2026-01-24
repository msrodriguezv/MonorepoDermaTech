import 'package:flutter/material.dart';

// --- AUTH GUARD IMPORT ---
// This is entry point that handles session persistence.
import 'features/auth/presentation/screens/auth_check_screen.dart';

void main() {
  // Ensure that the Flutter engine is fully initialized before executing any logic.
  // This is critical when using platform channels (like FlutterSecureStorage) at startup.
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const DermatechApp());
}

/// **DermatechApp**
/// The root widget of the application.
class DermatechApp extends StatelessWidget {
  const DermatechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dermatech Mobile',
      
      // Global Theme Configuration
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A2342)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),

      // We do not load LoginScreen directly. We load AuthCheckScreen first.
      // This allows the app to check for an existing session (Token) 
      // and redirect to the Dashboard automatically.
      home: const AuthCheckScreen(),
    );
  }
}