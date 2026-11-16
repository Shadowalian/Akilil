import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_professional_screen.dart';
import 'features/auth/two_factor_setup_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/sessions/sessions_screen.dart';
import 'features/sessions/session_host_screen.dart';
import 'features/availability/availability_screen.dart';
import 'features/clients/clients_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/post_session/post_session_notes_screen.dart';
import 'features/earnings/earnings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/groups/groups_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const login    = '/login';
  static const register = '/register';
  static const setup2fa = '/2fa-setup';
  static const onboarding = '/onboarding';
  static const home     = '/';
  static const appts    = '/sessions';
  static const availability = '/availability';
  static const clients  = '/clients';
  static const groups   = '/groups';
  static const earnings = '/earnings';
  static const profile  = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Same instance the login screen updates — a second AuthController here
  // used to swallow successful logins (router never saw the user).
  final authNotifier = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.setup2fa;
      if (authNotifier.mustSetup2FA) {
        return isAuthRoute ? null : AppRoutes.setup2fa;
      }
      if (authNotifier.isAuthenticated == false && !isAuthRoute) {
        return AppRoutes.login;
      }
      if (authNotifier.isAuthenticated == true && isAuthRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // Auth surface — no shell.
      GoRoute(path: AppRoutes.login,    builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterProfessionalScreen()),
      GoRoute(path: AppRoutes.setup2fa, builder: (_, __) => const TwoFactorSetupScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),

      // Authenticated shell with bottom nav.
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const DashboardScreen()),
          GoRoute(
            path: AppRoutes.appts,
            builder: (_, __) => const SessionsScreen(),
            routes: [
              GoRoute(
                path: ':id/host',
                builder: (_, s) => SessionHostScreen(appointmentId: s.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/notes',
                builder: (_, s) =>
                    PostSessionNotesScreen(appointmentId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: AppRoutes.availability, builder: (_, __) => const AvailabilityScreen()),
          GoRoute(path: AppRoutes.groups, builder: (_, __) => const GroupsScreen(), routes: [
            GoRoute(
              path: 'meetings/:id/host',
              builder: (_, s) => GroupMeetingHostScreen(
                meetingId: s.pathParameters['id']!,
                asHost: true,
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (_, s) =>
                  GroupDetailScreen(groupId: s.pathParameters['id']!),
            ),
          ]),
          GoRoute(path: AppRoutes.clients,  builder: (_, __) => const ClientsScreen()),
          GoRoute(path: AppRoutes.earnings, builder: (_, __) => const EarningsScreen()),
          GoRoute(path: AppRoutes.profile,  builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});