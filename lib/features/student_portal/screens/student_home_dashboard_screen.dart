import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';
import '../widgets/class_card.dart';
import '../widgets/empty_classes_state.dart';
import '../widgets/error_state_view.dart';
import '../widgets/insight_card.dart';
import '../widgets/live_status_badge.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/performance_tile.dart';
import '../widgets/student_feature_button.dart';
import '../widgets/emergency_alert_banner.dart';
import '../../parent_portal/widgets/notification_badge.dart';
import '../../../controllers/notification_controller.dart';
class StudentHomeDashboardScreen extends StatefulWidget {
  const StudentHomeDashboardScreen({super.key});

  @override
  State<StudentHomeDashboardScreen> createState() => _StudentHomeDashboardScreenState();
}

class _StudentHomeDashboardScreenState extends State<StudentHomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<StudentPortalController>().ensureInitialized(auth.currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<StudentPortalController>();
    final dashboard = controller.dashboard;

    return Scaffold(
      body: switch (controller.state) {
        StudentPortalLoadState.loading => const StudentDashboardSkeleton(),
        StudentPortalLoadState.error => StudentErrorStateView(
            message: controller.errorMessage ?? 'Failed to load student dashboard',
            onRetry: () => controller.loadDashboard(user: auth.currentUser, forceRefresh: true),
          ),
        _ => _buildBody(context, auth, controller, dashboard),
      },
      floatingActionButton: (controller.state == StudentPortalLoadState.success || controller.state == StudentPortalLoadState.refreshing)
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(AppRoutes.aiChat, extra: {
                  'role': 'student',
                  'contextData': {
                    'overallAttendance': dashboard?.overallAttendancePercentage,
                    'overallGrade': dashboard?.overallGradePercentage,
                    'recentScores': dashboard?.recentScores.map((s) => {
                          'assignment': s.assignmentTitle,
                          'percentage': s.percentage,
                        }).toList(),
                    'classes': dashboard?.classes.map((c) => c.classroomName).toList(),
                    'todaySnapshot': dashboard?.todaySnapshot,
                  },
                  'studentId': auth.currentUser?.id?.toString(),
                  'schoolId': auth.currentUser?.schoolId?.toString(),
                });
              },
              backgroundColor: const Color(0xFFFF8A00),
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
              label: const Text('Chat with AI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuthController auth,
    StudentPortalController controller,
    StudentDashboardData? dashboard,
  ) {
    final data = dashboard;

    return RefreshIndicator(
      onRefresh: () => controller.refresh(user: auth.currentUser),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            backgroundColor: const Color(0xFF0B1220),
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F0B0A), Color(0x80E52E71), Color(0xFFFF8A00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Welcome ${auth.currentUser?.fullName ?? 'Student'}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const LiveStatusBadge(isConnected: true),
                            Consumer<NotificationController>(
                              builder: (context, notificationCtrl, _) {
                                return NotificationBadge(
                                  count: notificationCtrl.unreadCount,
                                  child: IconButton(
                                    onPressed: () => context.push('/notifications'),
                                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              onPressed: () => context.go('/profile'),
                              icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: PerformanceTile(
                                label: 'Attendance',
                                value: _pct(data?.overallAttendancePercentage),
                                icon: Icons.how_to_reg_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PerformanceTile(
                                label: 'Grades',
                                value: _pct(data?.overallGradePercentage),
                                icon: Icons.grade_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PerformanceTile(
                                label: 'Classes',
                                value: '${data?.classCount ?? 0}',
                                icon: Icons.menu_book_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: EmergencyAlertBanner(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _snapshotCard(context, data),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _featureGrid(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Enrolled Classes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.studentFeed),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
          ),
          if ((data?.classes ?? const []).isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: EmptyClassesState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList.builder(
                itemCount: data!.classes.length,
                itemBuilder: (context, index) {
                  final item = data.classes[index];
                  return ClassCard(
                    data: item,
                    onViewPerformance: () => context.go('/student/class/${item.classroomId}'),
                  );
                },
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Scores',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        final firstClass = data?.classes.isNotEmpty == true ? data!.classes.first : null;
                        if (firstClass == null) {
                          context.go(AppRoutes.studentFeed);
                          return;
                        }
                        context.go(AppRoutes.studentPerformance(firstClass.classroomId));
                      },
                    child: const Text('Report'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _recentScores(context, data?.recentScores ?? const <ScorePoint>[]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: InsightCard(
                insight: data?.defaultInsight ?? const StudentInsight(
                  strengths: <String>[],
                  weaknesses: <String>[],
                  recommendations: <String>[],
                  generatedByAi: false,
                  summary: 'Loading insights...',
                ),
                  onTap: () {
                    final firstClass = data?.classes.isNotEmpty == true ? data!.classes.first : null;
                    final target = firstClass == null
                        ? AppRoutes.studentInsights
                        : '${AppRoutes.studentInsights}?classroomId=${firstClass.classroomId}';
                    context.go(target);
                  },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: _notifications(context, data?.notifications ?? const <String>[]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _snapshotCard(BuildContext context, StudentDashboardData? data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0F172A), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today Snapshot', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(data?.todaySnapshot ?? 'Loading snapshot...'),
        ],
      ),
    );
  }

  Widget _recentScores(BuildContext context, List<ScorePoint> scores) {
    if (scores.isEmpty) {
      return Container(
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: const Text('No marks available'),
      );
    }

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: scores.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final score = scores[index];
          return Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(score.assignmentTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${score.percentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _notifications(BuildContext context, List<String> notifications) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...notifications.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $note'),
            ),
          ),
        ],
      ),
    );
  }

  String _pct(double? value) => value == null ? '--' : '${value.toStringAsFixed(1)}%';

  Widget _featureGrid(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        StudentFeatureButton(
          title: 'Attendance',
          icon: Icons.fact_check_outlined,
          onTap: () => context.push(AppRoutes.studentAttendance),
        ),
        StudentFeatureButton(
          title: 'Timetable',
          icon: Icons.schedule_outlined,
          onTap: () => context.push(AppRoutes.studentTimetable),
        ),
        StudentFeatureButton(
          title: 'Report Card',
          icon: Icons.bar_chart_rounded,
          onTap: () => context.push(AppRoutes.studentReportCard),
        ),
        StudentFeatureButton(
          title: 'Announcements',
          icon: Icons.campaign_outlined,
          badgeCount: 2, // Example badge count
          onTap: () => context.push(AppRoutes.studentAnnouncements),
        ),
        StudentFeatureButton(
          title: 'Assignments',
          icon: Icons.assignment_outlined,
          onTap: () => context.push(AppRoutes.studentAssignments),
        ),
        StudentFeatureButton(
          title: 'Holidays',
          icon: Icons.event_available_outlined,
          onTap: () => context.push(AppRoutes.studentHolidays),
        ),
        StudentFeatureButton(
          title: 'Badges',
          icon: Icons.military_tech_outlined,
          onTap: () => context.push(AppRoutes.studentBadges),
        ),
        StudentFeatureButton(
          title: 'Risk Prediction',
          icon: Icons.warning_amber_rounded,
          onTap: () => context.push(AppRoutes.studentRiskPrediction),
        ),
        StudentFeatureButton(
          title: 'Burnout Detector',
          icon: Icons.battery_alert_rounded,
          onTap: () => context.push(AppRoutes.studentBurnout),
        ),
        StudentFeatureButton(
          title: 'Exam Readiness',
          icon: Icons.trending_up_rounded,
          onTap: () => context.push(AppRoutes.studentExamReadiness),
        ),
      ],
    );
  }
}

