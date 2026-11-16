import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/two_factor_setup_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/auth/assessment_screen.dart';
import 'features/auth/onboarding_prefs.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/discovery/professional_detail_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/booking/appointments_screen.dart';
import 'features/community/community_screen.dart';
import 'features/community/community_feed_screen.dart';
import 'features/goals_habits/goals_habits_screen.dart';
import 'features/payments/wallet_screen.dart';
import 'features/vents/vents_screen.dart';
import 'features/session_room/session_room_screen.dart';
import 'features/session_room/video_setup_screen.dart';
import 'features/messaging/conversations_screen.dart';
import 'features/messaging/conversation_screen.dart';
import 'features/journal/journal_list_screen.dart';
import 'features/journal/journal_editor_screen.dart';
import 'features/journal/mood_log_screen.dart';
import 'features/journal/mood_analytics_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/today/today_screen.dart';
import 'features/groups/groups_screen.dart';
// Clinical & care features
import 'features/worksheets/worksheets_screen.dart';
import 'features/worksheets/worksheet_detail_screen.dart';
import 'features/crisis/crisis_screen.dart';
import 'features/crisis/safety_plan_screen.dart';
import 'features/assessments/symptom_tracker_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/subscription_screen.dart';
import 'features/settings/switch_therapist_screen.dart';

/// Centralized route names — every screen imports these constants instead
/// of hardcoding strings, so renames are safe and the router/redirect
/// logic can reason about auth state without string spelunking.
class AppRoutes {
  AppRoutes._();
  static const welcome  = '/welcome';
  static const onboarding = '/onboarding';
  static const assessment = '/assessment';
  static const login    = '/login';
  static const register = '/register';
  static const setup2fa = '/2fa-setup';
  static const home     = '/';
  static const today    = '/today';
  static const appts    = '/appointments';
  static const conversations = '/messages';
  static const journalList   = '/journal';
  static const moodLog       = '/mood';
  static const moodAnalytics = '/mood/analytics';
  static const profile       = '/profile';
  static const community     = '/community';
  static const vents         = '/vents';
  static const goals         = '/goals';
  static const wallet        = '/wallet';
  static const groups        = '/groups';
  // Clinical & care
  static const worksheets      = '/worksheets';
  static const crisis          = '/crisis';
  static const safetyPlan      = '/crisis/safety-plan';
  static const assessments     = '/assessments';
  static const notifications   = '/notifications';
  static const settings        = '/settings';
  static const subscription    = '/settings/subscription';
  static const switchTherapist = '/settings/switch-therapist';
}

/// The single go_router instance for the user app.
///
/// We wrap the production [GoRouter] in a Provider so it can be re-created
/// in tests (override the provider with a fresh router). The `refreshListenable`
/// is bound to the [AuthController] — when login/logout changes the auth
/// state, the router re-evaluates its `redirect` rules and pushes the
/// user to the right surface.
final routerProvider = Provider<GoRouter>((ref) {
  // Must share the same instance screens mutate — a second AuthController
  // would never see login/register notifyListeners, so redirects stall.
  final authNotifier = ref.read(authControllerProvider);
  final onboardingDone = ref.watch(onboardingDoneProvider);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isPreAuth = loc == AppRoutes.welcome ||
          loc == AppRoutes.onboarding ||
          loc == AppRoutes.assessment ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.setup2fa;

      if (authNotifier.isBootstrapping || onboardingDone == null) {
        return null;
      }

      if (authNotifier.mustSetup2FA) {
        return loc == AppRoutes.setup2fa ? null : AppRoutes.setup2fa;
      }

      if (authNotifier.isAuthenticated == true) {
        if (isPreAuth) return AppRoutes.today;
        return null;
      }

      // Logged out
      if (onboardingDone == false) {
        if (loc == AppRoutes.welcome ||
            loc == AppRoutes.onboarding ||
            loc == AppRoutes.assessment ||
            loc == AppRoutes.login ||
            loc == AppRoutes.register) {
          return null;
        }
        return AppRoutes.welcome;
      }

      // Onboarding finished — land on auth screens only
      if (loc == AppRoutes.welcome ||
          loc == AppRoutes.onboarding ||
          loc == AppRoutes.assessment) {
        return AppRoutes.register;
      }
      if (!isPreAuth) return AppRoutes.login;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.assessment,
        builder: (_, _) => const AssessmentScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: AppRoutes.setup2fa, builder: (_, _) => const TwoFactorSetupScreen()),

      // Authenticated shell with bottom nav.
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.today,
            builder: (_, _) => const TodayScreen(),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const DiscoveryScreen(),
            routes: [
              GoRoute(
                path: 'pros/:id',
                builder: (_, s) => ProfessionalDetailScreen(proId: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'book',
                    builder: (_, s) => BookingScreen(proId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.appts,
            builder: (_, _) => const AppointmentsScreen(),
            routes: [
              GoRoute(
                path: ':id/room',
                builder: (_, s) => SessionRoomScreen(appointmentId: s.pathParameters['id']!),
              ),
              GoRoute(
                path: ':id/setup',
                builder: (_, s) => VideoSetupScreen(appointmentId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.conversations,
            builder: (_, _) => const ConversationsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => ConversationScreen(conversationId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.journalList,
            builder: (_, _) => const JournalListScreen(),
            routes: [
              GoRoute(path: 'edit',     builder: (_, _) => const JournalEditorScreen()),
              GoRoute(
                path: ':id',
                builder: (_, s) => JournalEditorScreen(entryId: s.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.moodLog,
            builder: (_, _) => const MoodLogScreen(),
            routes: [
              GoRoute(path: 'analytics', builder: (_, _) => const MoodAnalyticsScreen()),
            ],
          ),
          GoRoute(
            path: AppRoutes.community,
            builder: (_, _) => const CommunityScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    CommunityFeedScreen(channelId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.vents,
            builder: (_, _) => const VentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.goals,
            builder: (_, _) => const GoalsHabitsScreen(),
          ),
          GoRoute(
            path: AppRoutes.wallet,
            builder: (_, _) => const WalletScreen(),
          ),
          GoRoute(
            path: AppRoutes.groups,
            builder: (_, _) => const ClientGroupsScreen(),
            routes: [
              GoRoute(
                path: 'meetings/:id/join',
                builder: (_, s) => ClientGroupMeetingScreen(
                  meetingId: s.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    ClientGroupDetailScreen(groupId: s.pathParameters['id']!),
              ),
            ],
          ),
          // ── Clinical & care routes ──────────────────────────────────
          GoRoute(
            path: AppRoutes.worksheets,
            builder: (_, _) => const WorksheetsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) =>
                    WorksheetDetailScreen(worksheetId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.crisis,
            builder: (_, _) => const CrisisScreen(),
          ),
          GoRoute(
            path: AppRoutes.safetyPlan,
            builder: (_, _) => const SafetyPlanScreen(),
          ),
          GoRoute(
            path: AppRoutes.assessments,
            builder: (_, _) => const SymptomTrackerScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, _) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.subscription,
            builder: (_, _) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: AppRoutes.switchTherapist,
            builder: (_, _) => const SwitchTherapistScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});