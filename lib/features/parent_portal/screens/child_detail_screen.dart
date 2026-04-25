import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/alert_banner.dart';
import '../widgets/attendance_progress_ring.dart';
import '../widgets/grade_bar.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/section_header.dart';

class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({required this.childId, super.key});

  final int childId;

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  late Future<ChildDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ChildDetailData> _load({bool forceRefresh = false}) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      return Future<ChildDetailData>.error(StateError('Unauthorized user role.'));
    }

    return context.read<ParentPortalController>().loadChildDetail(
          user: user,
          childId: widget.childId,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Unauthorized user role.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Child Detail')),
      body: FutureBuilder<ChildDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const DetailLoadingSkeleton();
          }

          if (snapshot.hasError) {
            return ErrorStateView(
              message: 'Failed to load child detail screen',
              onRetry: () => setState(() => _future = _load(forceRefresh: true)),
            );
          }

          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('No child report found'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load(forceRefresh: true));
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _childProfileHeader(context, detail),
                const SizedBox(height: 14),
                if (detail.child.feeStatus == FeeStatusType.overdue)
                  const AlertBanner(
                    status: FeeStatusType.overdue,
                    message: 'Urgent: Fee is overdue. Please clear dues immediately.',
                  )
                else if (detail.child.feeStatus == FeeStatusType.pending)
                  const AlertBanner(
                    status: FeeStatusType.pending,
                    message: 'Fee is pending. Please complete payment before due date.',
                  ),
                SectionHeader(title: 'Overall Stats'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AttendanceProgressRing(value: detail.child.attendancePercentage),
                    const SizedBox(width: 16),
                    Expanded(child: GradeBar(value: detail.child.averageGradePercentage)),
                  ],
                ),
                const SizedBox(height: 18),
                SectionHeader(title: 'Classrooms', subtitle: 'Tap classroom for drill-down report'),
                const SizedBox(height: 10),
                ...detail.classrooms.map(
                  (classroom) => Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      title: Text(classroom.classroomName),
                      subtitle: Text(
                        'Attendance: ${classroom.attendancePercentage?.toStringAsFixed(1) ?? '--'}%  '
                        'Avg Score: ${classroom.averageScorePercentage?.toStringAsFixed(1) ?? '--'}%',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => context.go('/parent/child/${widget.childId}/classroom/${classroom.classroomId}'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(title: 'Recent Assignment Scores'),
                const SizedBox(height: 8),
                if (detail.recentAssignments.isEmpty)
                  const _EmptyLine(text: 'No grades yet')
                else
                  ...detail.recentAssignments.map(
                    (assignment) => Card(
                      child: ListTile(
                        title: Text(assignment.assignmentTitle),
                        subtitle: Text('${assignment.classroomName} • ${_fmtDate(assignment.submittedAt)}'),
                        trailing: Text('${assignment.percentage.toStringAsFixed(1)}%'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SectionHeader(title: 'Fee History'),
                const SizedBox(height: 8),
                if (detail.feeHistory.isEmpty)
                  const _EmptyLine(text: 'No fee records found')
                else
                  ...detail.feeHistory.map(
                    (fee) => Card(
                      child: ListTile(
                        title: Text('₹${fee.amount.toStringAsFixed(0)}'),
                        subtitle: Text('Due: ${_fmtDate(fee.dueDate)}'),
                        trailing: Text(_feeLabel(fee.status)),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SectionHeader(title: 'Attendance Chart'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: detail.attendanceTimeline.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final point = detail.attendanceTimeline[i];
                      final color = point.status == 'PRESENT'
                          ? const Color(0xFF16A34A)
                          : point.status == 'LATE'
                              ? const Color(0xFFF97316)
                              : const Color(0xFFDC2626);

                      return Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(point.status, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${point.sessionDate.month}/${point.sessionDate.day}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(title: 'Subject Performance'),
                const SizedBox(height: 8),
                ...detail.subjectPerformance.map(
                  (subject) => Card(
                    child: ListTile(
                      title: Text(subject.subject),
                      trailing: Text(subject.averagePercentage == null
                          ? 'No grades yet'
                          : '${subject.averagePercentage!.toStringAsFixed(1)}%'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export PDF will be available in Phase-4.')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export Report PDF'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _childProfileHeader(BuildContext context, ChildDetailData detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.school_rounded, color: Color(0xFF0369A1), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.child.childName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.child.classLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _feeLabel(FeeStatusType status) {
    switch (status) {
      case FeeStatusType.paid:
        return 'PAID';
      case FeeStatusType.pending:
        return 'PENDING';
      case FeeStatusType.overdue:
        return 'OVERDUE';
      case FeeStatusType.none:
        return 'NONE';
    }
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
