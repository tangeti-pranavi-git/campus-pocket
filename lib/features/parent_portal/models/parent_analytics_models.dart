import 'package:flutter/material.dart';

enum SupportPriority { low, medium, high }

class ActionPlanItem {
  final String title;
  final String description;
  final IconData icon;

  const ActionPlanItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class InterventionCoachData {
  final int supportScore;
  final SupportPriority priority;
  final String summary;
  final List<ActionPlanItem> actionPlan;
  final List<String> academicActions;
  final List<String> emotionalTips;
  final List<String> teacherFollowups;

  const InterventionCoachData({
    required this.supportScore,
    required this.priority,
    required this.summary,
    required this.actionPlan,
    required this.academicActions,
    required this.emotionalTips,
    required this.teacherFollowups,
  });
}

enum BlindSpotSeverity { green, yellow, red }

class HiddenAlert {
  final String title;
  final String message;
  final BlindSpotSeverity severity;
  final String insight;

  const HiddenAlert({
    required this.title,
    required this.message,
    required this.severity,
    required this.insight,
  });
}

class BlindSpotData {
  final int hiddenRiskScore;
  final BlindSpotSeverity overallSeverity;
  final List<HiddenAlert> alerts;
  final List<String> suggestedActions;
  final String aiInsight;

  const BlindSpotData({
    required this.hiddenRiskScore,
    required this.overallSeverity,
    required this.alerts,
    required this.suggestedActions,
    required this.aiInsight,
  });
}
