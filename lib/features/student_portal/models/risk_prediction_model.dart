enum RiskLevel { low, medium, high }

class RiskPredictionModel {
  final int studentId;
  final String studentName;
  final int riskScore;
  final RiskLevel riskLevel;
  final double? attendancePct;
  final double? avgMarksPct;
  final int missingAssignments;
  final double trendDelta;
  final List<String> reasons;
  final List<String> actions;

  const RiskPredictionModel({
    required this.studentId,
    required this.studentName,
    required this.riskScore,
    required this.riskLevel,
    this.attendancePct,
    this.avgMarksPct,
    required this.missingAssignments,
    required this.trendDelta,
    required this.reasons,
    required this.actions,
  });
}
