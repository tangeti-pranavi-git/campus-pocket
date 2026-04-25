import '../models/student_analytics_models.dart';

class BurnoutService {
  BurnoutData calculateBurnout(Map<String, dynamic> rawData) {
    if (rawData.isEmpty) {
      return const BurnoutData(
        score: 0,
        status: BurnoutStatus.healthy,
        metrics: [],
        suggestions: ["Enroll in classes to start tracking your academic health."],
        weeklyLoad: [0, 0, 0, 0, 0, 0, 0],
        aiSummary: "No data available.",
      );
    }

    final attendanceRows = rawData['attendance'] as List<dynamic>;
    final submissionRows = rawData['submissions'] as List<dynamic>;

    int score = 0;
    final List<BurnoutMetric> metrics = [];
    final List<String> suggestions = [];

    // 1. Attendance Drop (+20)
    // Logic: Compare last 5 sessions with previous 5
    if (attendanceRows.length >= 10) {
      final recent = attendanceRows.take(5).where((r) => r['status'] == 'PRESENT' || r['status'] == 'LATE').length;
      final previous = attendanceRows.skip(5).take(5).where((r) => r['status'] == 'PRESENT' || r['status'] == 'LATE').length;
      if (recent < previous) {
        score += 20;
        metrics.add(const BurnoutMetric(label: "Attendance Drop", value: "Declining", impact: 20));
        suggestions.add("Try to attend your next 3 classes consecutively.");
      }
    }

    // 2. Pending Assignments (+25)
    final pendingCount = submissionRows.where((s) => s['score'] == null).length;
    if (pendingCount >= 3) {
      score += 25;
      metrics.add(BurnoutMetric(label: "Pending Tasks", value: "$pendingCount pending", impact: 25));
      suggestions.add("Focus on completing the oldest pending assignment today.");
    }

    // 3. Marks Decline (+20)
    if (submissionRows.length >= 4) {
      final recentAvg = _avg(submissionRows.take(2));
      final previousAvg = _avg(submissionRows.skip(2).take(2));
      if (recentAvg < previousAvg - 5) {
        score += 20;
        metrics.add(const BurnoutMetric(label: "Performance Dip", value: "Scores falling", impact: 20));
        suggestions.add("Review the feedback on your last two assignments.");
      }
    }

    // 4. Deadlines this week (+20)
    // For simplicity, we count assignments due in next 7 days (mocked as constant if no real date logic)
    final deadlines = 3; // Mocked for demonstration as requested
    if (deadlines >= 3) {
      score += 20;
      metrics.add(BurnoutMetric(label: "Heavy Workload", value: "$deadlines deadlines", impact: 20));
      suggestions.add("Break down your largest project into 3 small steps.");
    }

    score = score.clamp(0, 100);
    
    BurnoutStatus status = BurnoutStatus.healthy;
    if (score >= 65) {
      status = BurnoutStatus.burnoutRisk;
    } else if (score >= 35) {
      status = BurnoutStatus.moderateStress;
    }

    if (suggestions.isEmpty) {
      suggestions.add("Keep maintaining your current study-life balance.");
    }
    
    suggestions.add("Take a 20-minute walk to reset your focus.");
    suggestions.add("Ensure you get at least 7 hours of sleep tonight.");

    return BurnoutData(
      score: score,
      status: status,
      metrics: metrics,
      suggestions: suggestions,
      weeklyLoad: [0.2, 0.5, 0.8, 0.4, 0.9, 0.3, 0.1], // Mocked trend
      aiSummary: _generateAiSummary(status, metrics),
    );
  }

  double _avg(Iterable<dynamic> rows) {
    if (rows.isEmpty) return 0;
    return rows.map((r) => (r['percentage'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / rows.length;
  }

  String _generateAiSummary(BurnoutStatus status, List<BurnoutMetric> metrics) {
    if (status == BurnoutStatus.healthy) return "You are managing your workload effectively. Keep it up!";
    if (metrics.isEmpty) return "You're showing some signs of stress. Take it easy.";
    
    final reason = metrics.first.label.toLowerCase();
    return "Your stress level is increasing primarily due to $reason. Consider prioritizing your tasks.";
  }
}
