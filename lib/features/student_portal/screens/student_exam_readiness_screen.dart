import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_readiness_controller.dart';
import '../models/student_analytics_models.dart';
import '../widgets/analytics/analytics_widgets.dart';
import '../../../src/contexts/auth_controller.dart';
import '../../ai_chat/widgets/ai_particle_background.dart';

class StudentExamReadinessScreen extends StatefulWidget {
  const StudentExamReadinessScreen({super.key});

  @override
  State<StudentExamReadinessScreen> createState() => _StudentExamReadinessScreenState();
}

class _StudentExamReadinessScreenState extends State<StudentExamReadinessScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.currentUser != null) {
        context.read<ExamReadinessController>().loadReadinessData(auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExamReadinessController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Exam Readiness', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AiParticleBackground(
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.data == null
                ? const Center(child: Text('No data available'))
                : _buildContent(context, controller.data!),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExamReadinessData data) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 120),
          ScoreGaugeCard(
            score: data.overallReadiness,
            title: 'OVERALL READINESS',
            color: _getReadinessColor(data.overallReadiness),
          ),
          const SizedBox(height: 24),
          _buildAiInsight(data.aiSummary),
          const SizedBox(height: 32),
          const Text('SUBJECT BREAKDOWN', 
            style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...data.subjectReadiness.map((s) => ReadinessSubjectCard(
            subject: s.subjectName,
            score: s.score,
            color: _getLevelColor(s.level),
            recommendation: s.recommendation,
          )).toList(),
          const SizedBox(height: 24),
          ActionPlanCard(
            title: 'OPTIMIZED STUDY PLAN',
            icon: Icons.auto_stories_outlined,
            items: data.studyPlan,
          ),
          const SizedBox(height: 24),
          _buildTrendSection(data.confidenceTrend, theme.colorScheme.primary),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAiInsight(String summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(List<double> trend, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1412),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONFIDENCE TREND', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 24),
          ProgressChart(data: trend.map((e) => e / 100).toList(), color: color),
        ],
      ),
    );
  }

  Color _getReadinessColor(int score) {
    if (score >= 85) return Colors.greenAccent;
    if (score >= 65) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getLevelColor(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.ready: return Colors.greenAccent;
      case ReadinessLevel.needsRevision: return Colors.orangeAccent;
      case ReadinessLevel.highPriority: return Colors.redAccent;
    }
  }
}
