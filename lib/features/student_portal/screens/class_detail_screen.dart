import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';
import '../widgets/attendance_ring.dart';
import '../widgets/consistency_meter.dart';
import '../widgets/error_state_view.dart';
import '../widgets/loading_skeletons.dart';
import '../widgets/score_trend_chart.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({required this.classroomId, super.key});

  final int classroomId;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  late Future<ClassDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ClassDetailData> _load({bool forceRefresh = false}) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      return Future<ClassDetailData>.error(StateError('Unauthorized role'));
    }
    return context.read<StudentPortalController>().loadClassDetail(
          user: user,
          classroomId: widget.classroomId,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Detail')),
      body: FutureBuilder<ClassDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const StudentDetailSkeleton();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return StudentErrorStateView(
              message: 'Failed to load class detail',
              onRetry: () => setState(() => _future = _load(forceRefresh: true)),
            );
          }

          final detail = snapshot.data!;
          final scores = detail.scores.map((e) => e.percentage).toList(growable: false);

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
                Row(
                  children: [
                    AttendanceRing(value: detail.attendancePercentage),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ConsistencyMeter(value: _consistency(scores)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Session History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...detail.sessions.map(
                  (session) => Card(
                    child: ListTile(
                      title: Text(session.topic),
                      subtitle: Text('${session.sessionDate.day}/${session.sessionDate.month}/${session.sessionDate.year}'),
                      trailing: Text(session.status),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Assignment Scores', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ScoreTrendChart(points: scores),
                const SizedBox(height: 8),
                ...detail.scores.map(
                  (score) => Card(
                    child: ListTile(
                      title: Text(score.assignmentTitle),
                      subtitle: Text('${score.submittedAt.day}/${score.submittedAt.month}/${score.submittedAt.year}'),
                      trailing: Text('${score.percentage.toStringAsFixed(1)}%'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Improvement Tips', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...detail.improvementTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $tip'),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, ClassDetailData detail) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detail.classroomName, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Your class performance view', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  double _consistency(List<double> points) {
    if (points.length <= 1) return 100;
    final avg = points.reduce((a, b) => a + b) / points.length;
    final variance = points.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) / points.length;
    final std = math.sqrt(variance);
    return (100 - std * 2).clamp(0, 100).toDouble();
  }
}
