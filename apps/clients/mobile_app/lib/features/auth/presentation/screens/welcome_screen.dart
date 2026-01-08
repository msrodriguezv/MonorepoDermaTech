import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Responsive Welcome Screen.
/// 
/// This implementation solves the "Bottom Overflowed" error by using a 
/// SingleChildScrollView that only activates when the screen height is too small 
/// to fit the content. On larger screens, it remains centered and static.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // --- Theme Constants ---
  static const Color _dermaNavyBlue = Color(0xFF0A2342);
  static const Color _dermaBackgroundWhite = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dermaBackgroundWhite,
      // LayoutBuilder gives us the viewport constraints (height/width).
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // physics: const ClampingScrollPhysics(), // Optional: Changes scroll feel
            child: ConstrainedBox(
              // This forces the content to be AT LEAST as tall as the screen.
              // This ensures centering works on big screens.
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          // --- 1. Logo Section ---
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 160, // Slightly reduced for better fit on small screens
                              fit: BoxFit.contain,
                            ),
                          ),
                          
                          const SizedBox(height: 10),

                          // --- 2. Title & Tagline ---
                          const Text(
                            'DERMATECH UCE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32, // Adjusted for responsiveness
                              fontWeight: FontWeight.w900,
                              color: _dermaNavyBlue,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Gestión dermatológica inteligente\nal alcance de tu mano.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),

                          // Spacer is better than SizedBox here because it takes available space
                          // but collapses if space is tight.
                          const SizedBox(height: 30), 

                          // --- 3. Action Buttons ---
                          
                          // Primary Button: Login
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _dermaNavyBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 5,
                              shadowColor: _dermaNavyBlue.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Secondary Button: Register
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: const BorderSide(color: _dermaNavyBlue, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              foregroundColor: _dermaNavyBlue,
                            ),
                            child: const Text(
                              'CREAR CUENTA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: _dermaNavyBlue,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Version Footer
                          Text(
                            ' PROGRAMACION DISTRIUIDA',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}