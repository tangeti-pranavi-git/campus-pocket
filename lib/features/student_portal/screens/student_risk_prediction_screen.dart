import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/risk_prediction_controller.dart';
import '../models/risk_prediction_model.dart';
import '../widgets/risk/action_suggestion_card.dart';
import '../widgets/risk/insight_reason_tile.dart';
import '../widgets/risk/risk_gauge_card.dart';
import '../widgets/risk/trend_mini_chart.dart';
import '../widgets/risk/risk_skeleton_loader.dart';
import '../widgets/error_state_view.dart';

class StudentRiskPredictionScreen extends StatefulWidget {
  const StudentRiskPredictionScreen({super.key});

  @override
  State<StudentRiskPredictionScreen> createState() => _StudentRiskPredictionScreenState();
}

class _StudentRiskPredictionScreenState extends State<StudentRiskPredictionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      context.read<RiskPredictionController>().loadRiskData(user: auth.currentUser);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RiskPredictionController>();
    final auth = context.read<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Prediction'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refresh(user: auth.currentUser),
          ),
        ],
      ),
      body: switch (controller.state) {
        RiskPredictionLoadState.initial => const RiskSkeletonLoader(),
        RiskPredictionLoadState.loading => const RiskSkeletonLoader(),
        RiskPredictionLoadState.error => StudentErrorStateView(
            message: controller.errorMessage ?? 'An error occurred',
            onRetry: () => controller.refresh(user: auth.currentUser),
          ),
        RiskPredictionLoadState.loaded => _buildBody(context, controller.riskData, controller.explanation),
      },
    );
  }

  Widget _buildBody(BuildContext context, RiskPredictionModel? data, String? explanation) {
    if (data == null) {
      return const Center(child: Text('No risk data available'));
    }

    return RefreshIndicator(
      onRefresh: () => context.read<RiskPredictionController>().refresh(user: context.read<AuthController>().currentUser),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Risk Meter Gauge
              RiskGaugeCard(riskScore: data.riskScore, riskLevel: data.riskLevel, explanation: explanation),
              const SizedBox(height: 24),

              // 2. Trend Graph
              TrendMiniChart(trendDelta: data.trendDelta, scores: [data.avgMarksPct ?? 0]), // Simplified trend chart
              const SizedBox(height: 24),

              // 3. Key Reasons
              Text('Key Reasons', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...data.reasons.map((reason) => InsightReasonTile(reason: reason)).toList(),
              const SizedBox(height: 24),

              // 4. Improvement Actions
              Text('Action Plan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...data.actions.map((action) => ActionSuggestionCard(action: action)).toList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
