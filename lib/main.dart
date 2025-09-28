import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/student_enrollment_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/admin_results_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/content_management_screen.dart';
import 'screens/attendance_data_screen.dart';
import 'screens/admin_content_dashboard_screen.dart';
import 'screens/student_notes_screen.dart';
import 'screens/student_assignments_screen.dart';
import 'screens/admin_explore_management_screen.dart';
import 'models/content_model.dart';

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
      initialRoute: '/explore-more',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/student-enrollment': (context) => const StudentEnrollmentScreen(),
        '/explore-more': (context) => const ExploreScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/student-dashboard': (context) => const StudentDashboardScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/content-management': (context) => const ContentManagementScreen(),
        '/attendance-data': (context) => const AttendanceDataScreen(),
        '/admin-content-dashboard': (context) => const AdminContentDashboardScreen(),
        '/admin-results': (context) => const AdminResultsScreen(),
        '/admin-explore': (context) => const AdminExploreManagementScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/student-notes') {
          final args = settings.arguments as Map<String, dynamic>?;
          final Standard? standard = args?['standard'] as Standard?;
          final Board? board = args?['board'] as Board?;
          if (standard != null && board != null) {
            return MaterialPageRoute(
              builder: (_) => StudentNotesScreen(standard: standard, board: board),
            );
          }
        }
        if (settings.name == '/student-assignments') {
          final args = settings.arguments as Map<String, dynamic>?;
          final Standard? standard = args?['standard'] as Standard?;
          final Board? board = args?['board'] as Board?;
          if (standard != null && board != null) {
            return MaterialPageRoute(
              builder: (_) => StudentAssignmentsScreen(standard: standard, board: board),
            );
          }
        }
        return null;
      },
    );
  }
}