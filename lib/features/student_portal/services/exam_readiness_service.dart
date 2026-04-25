import '../models/student_analytics_models.dart';

class ExamReadinessService {
  ExamReadinessData calculateReadiness(Map<String, dynamic> rawData) {
    if (rawData.isEmpty) {
      return const ExamReadinessData(
        overallReadiness: 0,
        subjectReadiness: [],
        weakSubjects: [],
        studyPlan: ["Enroll in subjects to see exam readiness."],
        confidenceTrend: [0, 0, 0, 0, 0],
        aiSummary: "No data available.",
      );
    }

    final memberships = rawData['memberships'] as List<dynamic>;
    final attendanceRows = rawData['attendance'] as List<dynamic>;
    final submissionRows = rawData['submissions'] as List<dynamic>;

    final List<SubjectReadiness> subjectReadiness = [];
    final List<String> weakSubjects = [];

    for (final membership in memberships) {
      final classroom = membership['classroom'] as Map<String, dynamic>;
      final classId = classroom['id'] as int;
      final className = classroom['name'] as String;

      // Filter data for this subject
      final classAttendance = attendanceRows.where((r) {
        final session = r['session'] as Map<String, dynamic>?;
        return session?['classroom_id'] == classId;
      }).toList();

      final classSubmissions = submissionRows.where((r) {
        final assignment = r['assignment'] as Map<String, dynamic>?;
        return assignment?['classroom_id'] == classId;
      }).toList();

      // Calculation logic
      double attScore = 0;
      if (classAttendance.isNotEmpty) {
        final present = classAttendance.where((r) => r['status'] == 'PRESENT').length;
        attScore = (present / classAttendance.length) * 100;
      }

      double perfScore = 0;
      if (classSubmissions.isNotEmpty) {
        perfScore = classSubmissions
                .map((r) => (r['percentage'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) /
            classSubmissions.length;
      }

      final score = ((attScore * 0.4) + (perfScore * 0.6)).round();
      
      ReadinessLevel level = ReadinessLevel.highPriority;
      if (score >= 85) {
        level = ReadinessLevel.ready;
      } else if (score >= 65) {
        level = ReadinessLevel.needsRevision;
      }

      if (level == ReadinessLevel.highPriority) {
        weakSubjects.add(className);
      }

      subjectReadiness.add(SubjectReadiness(
        subjectName: className,
        score: score,
        level: level,
        recommendation: _getRec(level),
        priorityChapters: _getPriorityChapters(className, level),
      ));
    }

    final overall = subjectReadiness.isEmpty
        ? 0
        : (subjectReadiness.map((e) => e.score).reduce((a, b) => a + b) / subjectReadiness.length).round();

    return ExamReadinessData(
      overallReadiness: overall,
      subjectReadiness: subjectReadiness,
      weakSubjects: weakSubjects,
      studyPlan: _generateStudyPlan(weakSubjects),
      confidenceTrend: [65, 72, 68, 75, 80], // Mocked trend
      aiSummary: _generateAiSummary(overall, weakSubjects),
    );
  }

  String _getRec(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.ready: return "You are well-prepared. Keep reviewing key concepts.";
      case ReadinessLevel.needsRevision: return "Focused revision on weak topics will boost your score.";
      case ReadinessLevel.highPriority: return "Immediate attention required. Complete pending assignments.";
    }
  }

  List<String> _getPriorityChapters(String subject, ReadinessLevel level) {
    if (level == ReadinessLevel.ready) return ["Advanced Applications", "Previous Year Papers"];
    return ["Core Concepts", "Recent Assignment Topics", "Formulas & Definitions"];
  }

  List<String> _generateStudyPlan(List<String> weakSubjects) {
    if (weakSubjects.isEmpty) return ["Maintain current schedule", "Weekly full-length mock tests"];
    return [
      "Allocate 2 hours daily for ${weakSubjects.first}",
      "Resolve doubts in next class session",
      "Solve last 3 years question papers"
    ];
  }

  String _generateAiSummary(int overall, List<String> weak) {
    if (overall >= 85) return "Your overall readiness is excellent! You are set for success.";
    if (weak.isEmpty) return "Good progress overall. A few focused revision sessions will make you exam-ready.";
    return "Your overall readiness is $overall%. Urgent focus is needed on ${weak.join(', ')}.";
  }
}
