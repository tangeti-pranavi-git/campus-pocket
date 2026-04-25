import '../models/risk_prediction_model.dart';
import 'student_portal_repository.dart';
import '../services/risk_prediction_service.dart';

class RiskPredictionRepository {
  final StudentPortalRepository _studentPortalRepository;
  final RiskPredictionService _service;

  RiskPredictionRepository({
    StudentPortalRepository? studentPortalRepository,
    RiskPredictionService? service,
  })  : _studentPortalRepository = studentPortalRepository ?? StudentPortalRepository(),
        _service = service ?? RiskPredictionService();

  Future<RiskPredictionModel> getRiskPrediction({
    required int studentId,
    required String studentName,
    bool forceRefresh = false,
  }) async {
    final dashboard = await _studentPortalRepository.getDashboard(
      studentId: studentId,
      studentName: studentName,
      forceRefresh: forceRefresh,
    );

    final assignments = await _studentPortalRepository.getAssignments(studentId: studentId);
    
    // Count missing / pending assignments
    int missingAssignments = assignments.where((a) => a.status.toLowerCase() == 'pending' || a.status.toLowerCase() == 'missing').length;

    // Calculate trend from recent scores
    double trendDelta = 0;
    if (dashboard.recentScores.length >= 2) {
      final scores = dashboard.recentScores.map((e) => e.percentage).toList();
      final reversed = scores.reversed.toList();
      trendDelta = reversed.last - reversed.first;
    }

    return _service.calculateRisk(
      studentId: studentId,
      studentName: studentName,
      attendancePct: dashboard.overallAttendancePercentage,
      avgMarksPct: dashboard.overallGradePercentage,
      missingAssignments: missingAssignments,
      trendDelta: trendDelta,
    );
  }

  Future<String> getRiskExplanation(RiskPredictionModel model) async {
    return _service.generateExplanation(model);
  }
}
