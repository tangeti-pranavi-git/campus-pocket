import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/risk_prediction_model.dart';
import 'risk_badge.dart';

class RiskGaugeCard extends StatelessWidget {
  final int riskScore;
  final RiskLevel riskLevel;
  final String? explanation;

  const RiskGaugeCard({
    super.key,
    required this.riskScore,
    required this.riskLevel,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    Color gaugeColor;
    switch (riskLevel) {
      case RiskLevel.low:
        gaugeColor = Colors.greenAccent;
        break;
      case RiskLevel.medium:
        gaugeColor = Colors.orangeAccent;
        break;
      case RiskLevel.high:
        gaugeColor = Colors.redAccent;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RiskBadge(level: riskLevel),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: 180,
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          value: riskScore.toDouble(),
                          color: gaugeColor,
                          radius: 20,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (100 - riskScore).toDouble(),
                          color: gaugeColor.withOpacity(0.1),
                          radius: 20,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: 100, // Bottom half hidden
                          color: Colors.transparent,
                          radius: 20,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$riskScore',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: gaugeColor,
                              ),
                        ),
                        const Text(
                          'Risk Score',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (explanation != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: gaugeColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gaugeColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, color: gaugeColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        explanation!,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
