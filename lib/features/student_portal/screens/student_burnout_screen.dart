import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/burnout_controller.dart';
import '../models/student_analytics_models.dart';
import '../widgets/analytics/analytics_widgets.dart';
import '../../../src/contexts/auth_controller.dart';
import '../../ai_chat/widgets/ai_particle_background.dart';

class StudentBurnoutScreen extends StatefulWidget {
  const StudentBurnoutScreen({super.key});

  @override
  State<StudentBurnoutScreen> createState() => _StudentBurnoutScreenState();
}

class _StudentBurnoutScreenState extends State<StudentBurnoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.currentUser != null) {
        context.read<BurnoutController>().loadBurnoutData(auth.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BurnoutController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Academic Health', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
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

  Widget _buildContent(BuildContext context, BurnoutData data) {
    final color = _getStatusColor(data.status);
    final statusText = _getStatusText(data.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 120),
          ScoreGaugeCard(
            score: data.score,
            title: statusText,
            color: color,
          ),
          const SizedBox(height: 24),
          _buildAiInsight(data.aiSummary),
          const SizedBox(height: 24),
          _buildMetricsGrid(data.metrics),
          const SizedBox(height: 24),
          ActionPlanCard(
            title: 'RECOVERY PLAN',
            icon: Icons.healing_outlined,
            items: data.suggestions,
          ),
          const SizedBox(height: 24),
          _buildLoadChart(data.weeklyLoad, color),
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

  Widget _buildMetricsGrid(List<BurnoutMetric> metrics) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1412),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(m.value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('+${m.impact.toInt()} pts', style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadChart(List<double> load, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1412),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WEEKLY LOAD TREND', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 24),
          ProgressChart(data: load, color: color),
        ],
      ),
    );
  }

  Color _getStatusColor(BurnoutStatus status) {
    switch (status) {
      case BurnoutStatus.healthy: return Colors.greenAccent;
      case BurnoutStatus.moderateStress: return Colors.orangeAccent;
      case BurnoutStatus.burnoutRisk: return Colors.redAccent;
    }
  }

  String _getStatusText(BurnoutStatus status) {
    switch (status) {
      case BurnoutStatus.healthy: return 'HEALTHY';
      case BurnoutStatus.moderateStress: return 'MODERATE STRESS';
      case BurnoutStatus.burnoutRisk: return 'BURNOUT RISK';
    }
  }
}
