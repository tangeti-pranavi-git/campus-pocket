import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/parent_portal/screens/child_detail_screen.dart';
import '../features/parent_portal/screens/classroom_detail_screen.dart';
import '../features/parent_portal/screens/parent_announcements_screen.dart';
import '../features/parent_portal/screens/parent_assignments_screen.dart';
import '../features/parent_portal/screens/parent_attendance_screen.dart';
import '../features/parent_portal/screens/parent_fee_details_screen.dart';
import '../features/parent_portal/screens/parent_holiday_calendar_screen.dart';
import '../features/parent_portal/screens/parent_home_dashboard_screen.dart';
import '../features/parent_portal/screens/parent_report_card_screen.dart';
import '../features/parent_portal/screens/parent_teacher_messages_screen.dart';
import '../features/parent_portal/screens/parent_timetable_screen.dart';
import '../features/parent_portal/screens/parent_voice_assistant_screen.dart';
import '../features/parent_portal/screens/parent_intervention_coach_screen.dart';
import '../features/parent_portal/screens/parent_blind_spot_detector_screen.dart';
import '../features/parent_portal/screens/parent_student_portal_screen.dart';
import '../features/student_portal/screens/ai_insight_detail_screen.dart';
import '../features/student_portal/screens/class_detail_screen.dart';
import '../features/student_portal/screens/classroom_feed_screen.dart';
import '../features/student_portal/screens/performance_report_screen.dart';
import '../features/student_portal/screens/student_home_dashboard_screen.dart';
import '../features/student_portal/screens/student_attendance_screen.dart';
import '../features/student_portal/screens/student_timetable_screen.dart';
import '../features/student_portal/screens/student_report_card_screen.dart';
import '../features/student_portal/screens/student_announcements_screen.dart';
import '../features/student_portal/screens/student_assignments_screen.dart';
import '../features/student_portal/screens/student_holiday_calendar_screen.dart';
import '../features/student_portal/screens/student_badges_screen.dart';
import '../features/student_portal/screens/student_risk_prediction_screen.dart';
import '../features/student_portal/screens/student_burnout_screen.dart';
import '../features/student_portal/screens/student_exam_readiness_screen.dart';
import '../features/ai_chat/screens/ai_chat_screen.dart';
import '../routes/app_routes.dart';
import 'contexts/auth_controller.dart';
import 'guards/parent_guard.dart';
import 'guards/student_guard.dart';
import 'screens/loading_session_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/unauthorized_screen.dart';
import 'screens/notification_screen.dart';
import 'types/portal_user.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Listenable listenable) {
    listenable.addListener(notifyListeners);
  }
}

GoRouter buildRouter(AuthController auth) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: RouterRefreshNotifier(auth),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoading = auth.status == AuthStatus.loadingSession;
      final isLoggedIn = auth.status == AuthStatus.authenticated;
      final role = auth.currentUser?.role;

      if (isLoading && location != AppRoutes.loading && location != AppRoutes.splash) {
        return AppRoutes.loading;
      }

      if (location == AppRoutes.splash) {
        if (isLoading) return AppRoutes.loading;
        return isLoggedIn
            ? (role == UserRole.student ? AppRoutes.studentHome : AppRoutes.parentHome)
            : AppRoutes.login;
      }

      if (!isLoggedIn) {
        if (location == AppRoutes.login || location == AppRoutes.unauthorized) {
          return null;
        }
        return AppRoutes.login;
      }

      if (location == AppRoutes.login) {
        return role == UserRole.student ? AppRoutes.studentHome : AppRoutes.parentHome;
      }

      if (location.startsWith('/student') && role != UserRole.student) {
        return AppRoutes.unauthorized;
      }

      if (location.startsWith('/parent') && role != UserRole.parent) {
        return AppRoutes.unauthorized;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const LoadingSessionScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (context, state) => const StudentGuard(child: StudentHomeDashboardScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentFeed,
        builder: (context, state) => const StudentGuard(child: ClassroomFeedScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentAttendance,
        builder: (context, state) => const StudentGuard(child: StudentAttendanceScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentTimetable,
        builder: (context, state) => const StudentGuard(child: StudentTimetableScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentReportCard,
        builder: (context, state) => const StudentGuard(child: StudentReportCardScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentAnnouncements,
        builder: (context, state) => const StudentGuard(child: StudentAnnouncementsScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentAssignments,
        builder: (context, state) => const StudentGuard(child: StudentAssignmentsScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentHolidays,
        builder: (context, state) => const StudentGuard(child: StudentHolidayCalendarScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentBadges,
        builder: (context, state) => const StudentGuard(child: StudentBadgesScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentRiskPrediction,
        builder: (context, state) => const StudentGuard(child: StudentRiskPredictionScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentBurnout,
        builder: (context, state) => const StudentGuard(child: StudentBurnoutScreen()),
      ),
      GoRoute(
        path: AppRoutes.studentExamReadiness,
        builder: (context, state) => const StudentGuard(child: StudentExamReadinessScreen()),
      ),
      GoRoute(
        path: '/student/class/:classroomId',
        builder: (context, state) {
          final classroomId = int.tryParse(state.pathParameters['classroomId'] ?? '');
          if (classroomId == null) return const UnauthorizedScreen();
          return StudentGuard(child: ClassDetailScreen(classroomId: classroomId));
        },
      ),
      GoRoute(
        path: '/student/performance/:classroomId',
        builder: (context, state) {
          final classroomId = int.tryParse(state.pathParameters['classroomId'] ?? '');
          if (classroomId == null) return const UnauthorizedScreen();
          return StudentGuard(child: PerformanceReportScreen(classroomId: classroomId));
        },
      ),
      GoRoute(
        path: AppRoutes.studentInsights,
        builder: (context, state) {
          final classroomId = int.tryParse(state.uri.queryParameters['classroomId'] ?? '');
          return StudentGuard(child: AiInsightDetailScreen(classroomId: classroomId));
        },
      ),
      GoRoute(
        path: AppRoutes.parentHome,
        builder: (context, state) => const ParentGuard(child: ParentHomeDashboardScreen()),
      ),
      GoRoute(
        path: '/parent/child/:childId',
        builder: (context, state) {
          final childId = int.tryParse(state.pathParameters['childId'] ?? '');
          if (childId == null) return const UnauthorizedScreen();
          return ParentGuard(child: ChildDetailScreen(childId: childId));
        },
      ),
      GoRoute(
        path: '/parent/student/:childId',
        builder: (context, state) {
          final childId = int.tryParse(state.pathParameters['childId'] ?? '');
          if (childId == null) return const UnauthorizedScreen();
          return ParentGuard(child: ParentStudentPortalScreen(childId: childId));
        },
      ),
      GoRoute(
        path: '/parent/child/:childId/classroom/:classroomId',
        builder: (context, state) {
          final childId = int.tryParse(state.pathParameters['childId'] ?? '');
          final classroomId = int.tryParse(state.pathParameters['classroomId'] ?? '');
          if (childId == null || classroomId == null) return const UnauthorizedScreen();
          return ParentGuard(
            child: ClassroomDetailScreen(childId: childId, classroomId: classroomId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.parentAttendance,
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          return ParentGuard(child: ParentAttendanceScreen(childId: childId));
        },
      ),
      GoRoute(
        path: AppRoutes.parentTimetable,
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          return ParentGuard(child: ParentTimetableScreen(childId: childId));
        },
      ),
      GoRoute(
        path: AppRoutes.parentReportCard,
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          return ParentGuard(child: ParentReportCardScreen(childId: childId));
        },
      ),
      GoRoute(
        path: AppRoutes.parentAnnouncements,
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          return ParentGuard(child: ParentAnnouncementsScreen(childId: childId));
        },
      ),
      GoRoute(
        path: AppRoutes.parentAssignments,
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          return ParentGuard(child: ParentAssignmentsScreen(childId: childId));
        },
      ),
      GoRoute(
        path: AppRoutes.parentHolidays,
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          return ParentGuard(child: ParentHolidayCalendarScreen(childId: childId));
        },
      ),
      GoRoute(
        path: AppRoutes.parentFees,
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          return ParentGuard(child: ParentFeeDetailsScreen(childId: childId));
        },
      ),
      GoRoute(
        path: AppRoutes.parentMessages,
        builder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';
          return ParentGuard(child: ParentTeacherMessagesScreen(childId: childId));
        },
      ),
      GoRoute(
        path: AppRoutes.parentVoiceAssistant,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ParentGuard(
            child: ParentVoiceAssistantScreen(
              contextData: extra['contextData'] ?? {},
              studentId: extra['studentId']?.toString(),
              parentId: extra['parentId']?.toString(),
              schoolId: extra['schoolId']?.toString(),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.parentInterventionCoach,
        builder: (context, state) => const ParentGuard(child: ParentInterventionCoachScreen()),
      ),
      GoRoute(
        path: AppRoutes.parentBlindSpotDetector,
        builder: (context, state) => const ParentGuard(child: ParentBlindSpotDetectorScreen()),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AiChatScreen(
            contextData: extra['contextData'] ?? {},
            role: extra['role'] ?? 'student',
            studentId: extra['studentId']?.toString(),
            parentId: extra['parentId']?.toString(),
            schoolId: extra['schoolId']?.toString(),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
}
