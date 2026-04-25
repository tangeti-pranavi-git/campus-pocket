import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/student_portal_controller.dart';
import '../models/student_portal_models.dart';
import '../widgets/error_state_view.dart';
import '../widgets/loading_skeletons.dart';

class AiInsightDetailScreen extends StatefulWidget {
  const AiInsightDetailScreen({this.classroomId, super.key});

  final int? classroomId;

  @override
  State<AiInsightDetailScreen> createState() => _AiInsightDetailScreenState();
}

class _AiInsightDetailScreenState extends State<AiInsightDetailScreen> {
  late Future<StudentInsight> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StudentInsight> _load({bool forceRefresh = false}) {
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      return Future<StudentInsight>.error(StateError('Unauthorized role'));
    }
    return context.read<StudentPortalController>().loadInsight(
          user: user,
          classroomId: widget.classroomId,
          forceRefresh: forceRefresh,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Insights')),
      body: FutureBuilder<StudentInsight>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const StudentDetailSkeleton();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return StudentErrorStateView(
              message: 'Failed to load AI insight',
              onRetry: () => setState(() => _future = _load(forceRefresh: true)),
            );
          }

          final insight = snapshot.data!;

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
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                    ),
                  ),
                  child: Text(
                    insight.summary,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                _section(context, 'Strengths', insight.strengths),
                const SizedBox(height: 12),
                _section(context, 'Weaknesses', insight.weaknesses),
                const SizedBox(height: 12),
                _section(context, 'Recommendations', insight.recommendations),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text('No $title available')
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $item'),
                  )),
            const SizedBox(height: 4),
            Text(
              insightSourceText(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String insightSourceText() => 'AI-ready insight';
}
