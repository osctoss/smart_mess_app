import 'package:flutter/material.dart';
import '../../features/auth/splash/splash_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/signup/signup_screen.dart';
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

  /// Custom fade + slide page transition
  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case signup:
        return _buildRoute(const SignupScreen(), settings);
      case createMess:
        return _buildRoute(const CreateMessScreen(), settings);
      case selectMess:
        return _buildRoute(const SelectMessScreen(), settings);
      case clientHome:
        return _buildRoute(const ClientHomeScreen(), settings);
      case clientDashboard:
        return _buildRoute(const ClientDashboard(), settings);
      case clientAvailability:
        return _buildRoute(const AvailabilityScreen(), settings);
      case clientNotifications:
        return _buildRoute(const ClientNotificationsScreen(), settings);
      case clientProfile:
        return _buildRoute(const ProfileScreen(), settings);
      case changePassword:
        return _buildRoute(const ChangePasswordScreen(), settings);
      case changePhone:
        return _buildRoute(ChangePhoneScreen(), settings);
      case adminDashboard:
        return _buildRoute(const AdminDashboard(), settings);
      case menuManagement:
        return _buildRoute(const MenuScreen(), settings);
      case availabilityList:
        return _buildRoute(const AvailabilityListScreen(), settings);
      case membersList:
        return _buildRoute(const MembersScreen(), settings);
      case clientDetail:
        final user = settings.arguments as UserModel?;
        return _buildRoute(ClientDetailScreen(user: user), settings);
      case adminNotifications:
        return _buildRoute(const AdminNotificationsScreen(), settings);
      case attendance:
        return _buildRoute(const AttendanceScreen(), settings);
      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings,
        );
    }
  }
}
