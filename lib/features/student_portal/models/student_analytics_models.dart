enum BurnoutStatus { healthy, moderateStress, burnoutRisk }

class BurnoutMetric {
  final String label;
  final String value;
  final double impact;
  final bool isNegative;

  const BurnoutMetric({
    required this.label,
    required this.value,
    required this.impact,
    this.isNegative = true,
  });
}

class BurnoutData {
  final int score;
  final BurnoutStatus status;
  final List<BurnoutMetric> metrics;
  final List<String> suggestions;
  final List<double> weeklyLoad;
  final String aiSummary;

  const BurnoutData({
    required this.score,
    required this.status,
    required this.metrics,
    required this.suggestions,
    required this.weeklyLoad,
    required this.aiSummary,
  });
}

enum ReadinessLevel { highPriority, needsRevision, ready }

class SubjectReadiness {
  final String subjectName;
  final int score;
  final ReadinessLevel level;
  final String recommendation;
  final List<String> priorityChapters;

  const SubjectReadiness({
    required this.subjectName,
    required this.score,
    required this.level,
    required this.recommendation,
    required this.priorityChapters,
  });
}

class ExamReadinessData {
  final int overallReadiness;
  final List<SubjectReadiness> subjectReadiness;
  final List<String> weakSubjects;
  final List<String> studyPlan;
  final List<double> confidenceTrend;
  final String aiSummary;

  const ExamReadinessData({
    required this.overallReadiness,
    required this.subjectReadiness,
    required this.weakSubjects,
    required this.studyPlan,
    required this.confidenceTrend,
    required this.aiSummary,
  });
}
