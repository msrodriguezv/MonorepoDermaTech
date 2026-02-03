import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/patients/presentation/screens/student_dashboard_screen.dart';

GoRouter createAppRouter(bool isAuthenticated) {
  return GoRouter(
    // If authenticated (Token exists in Storage), start at '/profile'.
    // Otherwise, start at '/login'.
    initialLocation: isAuthenticated ? '/profile' : '/login',
    
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const StudentDashboardScreen(),
      ),
    ],
    // Optional: Add redirect logic here for deeper security checks if needed
    redirect: (context, state) {
      // Example: Prevent logged-in users from visiting login page
      final isLoggingIn = state.uri.toString() == '/login';
      if (isAuthenticated && isLoggingIn) {
        return '/profile';
      }
      return null;
    },
  );
}