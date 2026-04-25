import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../widgets/class_card.dart';
import '../widgets/empty_classes_state.dart';
import '../widgets/error_state_view.dart';
import '../widgets/loading_skeletons.dart';

class ClassroomFeedScreen extends StatelessWidget {
  const ClassroomFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<StudentPortalController>();
    final dashboard = controller.dashboard;

    return Scaffold(
      appBar: AppBar(title: const Text('Classroom Feed')),
      body: switch (controller.state) {
        StudentPortalLoadState.loading => const StudentDashboardSkeleton(),
        StudentPortalLoadState.error => StudentErrorStateView(
            message: controller.errorMessage ?? 'Failed to load classes',
            onRetry: () => controller.loadDashboard(user: auth.currentUser, forceRefresh: true),
          ),
        _ => RefreshIndicator(
            onRefresh: () => controller.refresh(user: auth.currentUser),
            child: (dashboard?.classes ?? const []).isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 200),
                      EmptyClassesState(),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: dashboard!.classes
                        .map(
                          (item) => ClassCard(
                            data: item,
                            onViewPerformance: () => context.go('/student/class/${item.classroomId}'),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
      },
    );
  }
}
