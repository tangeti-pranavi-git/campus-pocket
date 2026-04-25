class StudentInsight {
  const StudentInsight({
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.generatedByAi,
    required this.summary,
  });

  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> recommendations;
  final bool generatedByAi;
  final String summary;
}

class ScorePoint {
  const ScorePoint({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.classroomId,
    required this.classroomName,
    required this.percentage,
    required this.submittedAt,
  });

  final int assignmentId;
  final String assignmentTitle;
  final int classroomId;
  final String classroomName;
  final double percentage;
  final DateTime submittedAt;
}

class SessionHistoryItem {
  const SessionHistoryItem({
    required this.sessionId,
    required this.classroomId,
    required this.sessionDate,
    required this.topic,
    required this.status,
  });

  final int sessionId;
  final int classroomId;
  final DateTime sessionDate;
  final String topic;
  final String status;
}

class ClassFeedItem {
  const ClassFeedItem({
    required this.classroomId,
    required this.classroomName,
    required this.teacher,
    required this.attendancePercentage,
    required this.recentScoreAverage,
    required this.nextSessionDate,
    required this.nextSessionTopic,
    required this.recentScores,
  });

  final int classroomId;
  final String classroomName;
  final String teacher;
  final double? attendancePercentage;
  final double? recentScoreAverage;
  final DateTime? nextSessionDate;
  final String? nextSessionTopic;
  final List<ScorePoint> recentScores;
}

class StudentDashboardData {
  const StudentDashboardData({
    required this.studentId,
    required this.studentName,
    required this.overallAttendancePercentage,
    required this.overallGradePercentage,
    required this.classCount,
    required this.classes,
    required this.recentScores,
    required this.notifications,
    required this.todaySnapshot,
    required this.defaultInsight,
  });

  final int studentId;
  final String studentName;
  final double? overallAttendancePercentage;
  final double? overallGradePercentage;
  final int classCount;
  final List<ClassFeedItem> classes;
  final List<ScorePoint> recentScores;
  final List<String> notifications;
  final String todaySnapshot;
  final StudentInsight defaultInsight;
}

class ClassDetailData {
  const ClassDetailData({
    required this.classroomId,
    required this.classroomName,
    required this.attendancePercentage,
    required this.sessions,
    required this.scores,
    required this.improvementTips,
    required this.trendDelta,
  });

  final int classroomId;
  final String classroomName;
  final double? attendancePercentage;
  final List<SessionHistoryItem> sessions;
  final List<ScorePoint> scores;
  final List<String> improvementTips;
  final double trendDelta;
}

class PerformanceReportData {
  const PerformanceReportData({
    required this.classroomId,
    required this.classroomName,
    required this.scores,
    required this.consistency,
    required this.averagePercentage,
    required this.trendDelta,
  });

  final int classroomId;
  final String classroomName;
  final List<ScorePoint> scores;
  final double consistency;
  final double? averagePercentage;
  final double trendDelta;
}

class StudentBadgeItem {
  const StudentBadgeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.earnedAt,
    required this.rarity,
  });

  final int id;
  final String title;
  final String category;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final String rarity;
}

class StudentHolidayItem {
  const StudentHolidayItem({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
  });

  final int id;
  final String title;
  final DateTime date;
  final String type;
}

class StudentAnnouncementItem {
  const StudentAnnouncementItem({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.category,
  });

  final int id;
  final String title;
  final String content;
  final DateTime date;
  final String category;
}

class StudentTimetableItem {
  const StudentTimetableItem({
    required this.id,
    required this.subject,
    required this.teacherName,
    required this.roomName,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
  });

  final int id;
  final String subject;
  final String teacherName;
  final String roomName;
  final String startTime;
  final String endTime;
  final int dayOfWeek;
}

class StudentAssignmentItem {
  const StudentAssignmentItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    required this.score,
    required this.totalScore,
  });

  final int id;
  final String title;
  final String subject;
  final DateTime dueDate;
  final String status;
  final double? score;
  final double? totalScore;
}
