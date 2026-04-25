import '../models/risk_prediction_model.dart';

class RiskPredictionService {
  RiskPredictionModel calculateRisk({
    required int studentId,
    required String studentName,
    required double? attendancePct,
    required double? avgMarksPct,
    required int missingAssignments,
    required double trendDelta,
  }) {
    // Risk score calculation (0-100, higher is worse)
    double attendanceRisk = attendancePct != null ? (100 - attendancePct).clamp(0, 100).toDouble() : 50.0;
    double gradeRisk = avgMarksPct != null ? (100 - avgMarksPct).clamp(0, 100).toDouble() : 50.0;
    double assignmentRisk = (missingAssignments * 20.0).clamp(0, 100).toDouble();
    double trendRisk = trendDelta < 0 ? (-trendDelta * 10.0).clamp(0, 100).toDouble() : 0.0;

    double finalScore = (attendanceRisk * 0.35) +
        (gradeRisk * 0.35) +
        (assignmentRisk * 0.20) +
        (trendRisk * 0.10);

    int score = finalScore.round().clamp(0, 100);

    RiskLevel level;
    if (score < 35) {
      level = RiskLevel.low;
    } else if (score < 65) {
      level = RiskLevel.medium;
    } else {
      level = RiskLevel.high;
    }

    List<String> reasons = [];
    List<String> actions = [];

    if (attendancePct != null && attendancePct < 75) {
      reasons.add('Attendance dropped to ${attendancePct.toStringAsFixed(1)}%');
      actions.add('Attend next 5 classes to improve attendance');
    }
    if (avgMarksPct != null && avgMarksPct < 60) {
      reasons.add('Average marks below 60% (${avgMarksPct.toStringAsFixed(1)}%)');
      actions.add('Practice daily for 30 mins');
    }
    if (missingAssignments > 0) {
      reasons.add('$missingAssignments assignments pending');
      actions.add('Submit pending assignments immediately');
    }
    if (trendDelta < -5) {
      reasons.add('Performance trend dropping by ${(-trendDelta).toStringAsFixed(1)}%');
      actions.add('Review recent topics and seek teacher help');
    }

    if (reasons.isEmpty) {
      reasons.add('All academic metrics look stable');
      actions.add('Keep up the good work');
    }

    return RiskPredictionModel(
      studentId: studentId,
      studentName: studentName,
      riskScore: score,
      riskLevel: level,
      attendancePct: attendancePct,
      avgMarksPct: avgMarksPct,
      missingAssignments: missingAssignments,
      trendDelta: trendDelta,
      reasons: reasons,
      actions: actions,
    );
  }

  Future<String> generateExplanation(RiskPredictionModel model) async {
    // If there is an AI service available, this can be swapped.
    // For now, using a smart rules engine fallback.
    String base = 'You are at ${model.riskLevel.name} risk mainly due to';
    if (model.reasons.length == 1 && model.reasons.first.contains('stable')) {
      return 'You are currently at a low academic risk. Keep up your excellent performance and continue submitting work on time.';
    }

    return '$base ${model.reasons.join(', ').toLowerCase()}.';
  }
}
