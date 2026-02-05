import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'config/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('es');
  usePathUrlStrategy();

  runApp(const DermatechApp());
}

class DermatechApp extends StatelessWidget {
  const DermatechApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routerConfig = createAppRouter();

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