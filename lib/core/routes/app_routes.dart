import 'package:flutter/material.dart';
import '../../features/auth/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/signup/signup_screen.dart';
import '../../features/auth/otp/otp_screen.dart';
import '../../features/auth/create_mess/create_mess_screen.dart';
import '../../features/auth/select_mess/select_mess_screen.dart';
import '../../features/client/dashboard/client_dashboard.dart';
import '../../features/client/availability/availability_screen.dart';
import '../../features/client/notifications/client_notifications_screen.dart';
import '../../features/client/home/client_home_screen.dart';
import '../../features/client/profile/profile_screen.dart';
import '../../features/client/profile/change_password_screen.dart';
import '../../features/client/profile/change_phone_screen.dart';
import '../../features/admin/dashboard/admin_dashboard.dart';
import '../../features/admin/menu/menu_screen.dart';
import '../../features/admin/availability_list/availability_list_screen.dart';
import '../../features/admin/members/members_screen.dart';
import '../../features/admin/members/client_detail_screen.dart';
import '../../features/admin/notifications/admin_notifications_screen.dart';
import '../../features/admin/attendance/attendance_screen.dart';
import '../../models/user_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String createMess = '/createMess';
  static const String selectMess = '/selectMess';
  static const String clientDashboard = '/clientDashboard';
  static const String clientAvailability = '/clientAvailability';
  static const String clientHome = '/clientHome';
  static const String clientNotifications = '/clientNotifications';
  static const String clientProfile = '/clientProfile';
  static const String changePassword = '/changePassword';
  static const String changePhone = '/changePhone';
  static const String adminDashboard = '/adminDashboard';
  static const String menuManagement = '/menuManagement';
  static const String availabilityList = '/availabilityList';
  static const String membersList = '/membersList';
  static const String clientDetail = '/clientDetail';
  static const String adminNotifications = '/adminNotifications';
  static const String attendance = '/attendance';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case createMess:
        return MaterialPageRoute(builder: (_) => const CreateMessScreen());
      case selectMess:
        return MaterialPageRoute(builder: (_) => const SelectMessScreen());
      case clientHome:
        return MaterialPageRoute(builder: (_) => const ClientHomeScreen());
      case clientDashboard:
        return MaterialPageRoute(builder: (_) => const ClientDashboard());
      case clientAvailability:
        return MaterialPageRoute(builder: (_) => const AvailabilityScreen());
      case clientNotifications:
        return MaterialPageRoute(builder: (_) => const ClientNotificationsScreen());
      case clientProfile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case changePassword:
        return MaterialPageRoute(builder: (_) => ChangePasswordScreen());
      case changePhone:
        return MaterialPageRoute(builder: (_) => ChangePhoneScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case menuManagement:
        return MaterialPageRoute(builder: (_) => const MenuScreen());
      case availabilityList:
        return MaterialPageRoute(builder: (_) => const AvailabilityListScreen());
      case membersList:
        return MaterialPageRoute(builder: (_) => const MembersScreen());
      case clientDetail:
        final user = settings.arguments as UserModel?;
        return MaterialPageRoute(builder: (_) => ClientDetailScreen(user: user));
      case adminNotifications:
        return MaterialPageRoute(builder: (_) => const AdminNotificationsScreen());
      case attendance:
        return MaterialPageRoute(builder: (_) => const AttendanceScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
