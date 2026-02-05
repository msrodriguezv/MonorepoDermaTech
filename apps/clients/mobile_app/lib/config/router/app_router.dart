import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/auth_check_screen.dart'; // Importa la nueva pantalla
import '../../features/patients/presentation/screens/student_dashboard_screen.dart';
import '../../features/patients/presentation/screens/book_appointment_screen.dart';
import '../../features/patients/presentation/screens/complete_profile_screen.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/', 
    
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthCheckScreen(),
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
        routes: [
          GoRoute(
            path: 'book', 
            builder: (context, state) => const BookAppointmentScreen(),
          ),
          GoRoute(
            path: 'complete',
            builder: (context, state) {
              final email = state.extra as String?; 
              return CompleteProfileScreen(email: email ?? '');
            },
          ),
        ],
      ),
    ],
  );
}