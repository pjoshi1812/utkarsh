import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/student_enrollment_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/student_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/student-enrollment': (context) => const StudentEnrollmentScreen(),
        '/explore-more': (context) => const ExploreScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/student-dashboard': (context) => const StudentDashboardScreen(),
      },
    );
  }
}
