import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/grade_bar.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/section_header.dart';

class ClassroomDetailScreen extends StatefulWidget {
  const ClassroomDetailScreen({
    required this.childId,
    required this.classroomId,
    super.key,
  });

  final int childId;
  final int classroomId;

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  late Future<ClassroomDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ClassroomDetailData> _load({bool forceRefresh = false}) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      return Future<ClassroomDetailData>.error(StateError('Unauthorized user role.'));
    }

    return context.read<ParentPortalController>().loadClassroomDetail(
          user: user,
          childId: widget.childId,
          classroomId: widget.classroomId,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classroom Detail')),
      body: FutureBuilder<ClassroomDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const DetailLoadingSkeleton();
          }

          if (snapshot.hasError || snapshot.data == null) {
            return ErrorStateView(
              message: 'Failed to load classroom detail',
              onRetry: () => setState(() => _future = _load(forceRefresh: true)),
            );
          }

          final detail = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load(forceRefresh: true));
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _header(context, detail),
                const SizedBox(height: 14),
                SectionHeader(title: 'Attendance'),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('Attendance %'),
                    trailing: Text('${detail.attendancePercentage?.toStringAsFixed(1) ?? '--'}%'),
                  ),
                ),
                const SizedBox(height: 14),
                SectionHeader(title: 'Average Score'),
                const SizedBox(height: 8),
                GradeBar(value: detail.averageScorePercentage),
                const SizedBox(height: 18),
                SectionHeader(title: 'Session History'),
                const SizedBox(height: 8),
                if (detail.sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No attendance records for this classroom'),
                  )
                else
                  ...detail.sessions.map(
                    (session) => Card(
                      child: ListTile(
                        title: Text(session.topic),
                        subtitle: Text(
                          '${session.sessionDate.day}/${session.sessionDate.month}/${session.sessionDate.year}',
                        ),
                        trailing: Text(session.status),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                SectionHeader(title: 'Assignments & Scores'),
                const SizedBox(height: 8),
                if (detail.assignments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No grades yet'),
                  )
                else
                  ...detail.assignments.map(
                    (assignment) => Card(
                      child: ListTile(
                        title: Text(assignment.assignmentTitle),
                        subtitle: Text(
                          '${assignment.score.toStringAsFixed(0)}/${assignment.total}',
                        ),
                        trailing: Text('${assignment.percentage.toStringAsFixed(1)}%'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, ClassroomDetailData detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.classroomName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Student: ${detail.childName}'),
        ],
      ),
    );
  }
}
