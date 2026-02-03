import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/storage/storage_service.dart';
import 'config/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize dependencies
  await initializeDateFormatting('es');
  usePathUrlStrategy(); // Removes the "#" from URL

  // 2. CHECK SESSION BEFORE APP STARTS (The Fix for F5)
  // We read the token from SharedPreferences (Web) or SecureStorage (Mobile).
  final storage = StorageService();
  final token = await storage.read(key: 'accessToken');

  // 3. Determine initial state
  final bool isAuthenticated = token != null && token.isNotEmpty;

  runApp(DermatechApp(isAuthenticated: isAuthenticated));
}
.
class DermatechApp extends StatelessWidget {
  final bool isAuthenticated;

  const DermatechApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
   
    final routerConfig = createAppRouter(isAuthenticated);

    return MaterialApp.router(
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

      routerConfig: routerConfig,
    );
  }
}