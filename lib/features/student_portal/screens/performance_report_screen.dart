import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';
import '../widgets/consistency_meter.dart';
import '../widgets/error_state_view.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/score_trend_chart.dart';

class PerformanceReportScreen extends StatefulWidget {
  const PerformanceReportScreen({required this.classroomId, super.key});

  final int classroomId;

  @override
  State<PerformanceReportScreen> createState() => _PerformanceReportScreenState();
}

class _PerformanceReportScreenState extends State<PerformanceReportScreen> {
  late Future<PerformanceReportData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PerformanceReportData> _load({bool forceRefresh = false}) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      return Future<PerformanceReportData>.error(StateError('Unauthorized role'));
    }
    return context.read<StudentPortalController>().loadPerformanceReport(
          user: user,
          classroomId: widget.classroomId,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Report')),
      body: FutureBuilder<PerformanceReportData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const StudentDetailSkeleton();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return StudentErrorStateView(
              message: 'Failed to load performance report',
              onRetry: () => setState(() => _future = _load(forceRefresh: true)),
            );
          }

          final report = snapshot.data!;
          final scores = report.scores.map((e) => e.percentage).toList(growable: false);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _load(forceRefresh: true));
              await _future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.classroomName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text('Average grade: ${report.averagePercentage?.toStringAsFixed(1) ?? '--'}%'),
                      const SizedBox(height: 10),
                      ConsistencyMeter(value: report.consistency),
                      const SizedBox(height: 10),
                      Text('Trend delta: ${report.trendDelta.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ScoreTrendChart(points: scores),
                const SizedBox(height: 12),
                ...report.scores.map(
                  (score) => Card(
                    child: ListTile(
                      title: Text(score.assignmentTitle),
                      subtitle: Text('${score.submittedAt.day}/${score.submittedAt.month}/${score.submittedAt.year}'),
                      trailing: Text('${score.percentage.toStringAsFixed(1)}%'),
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
}
