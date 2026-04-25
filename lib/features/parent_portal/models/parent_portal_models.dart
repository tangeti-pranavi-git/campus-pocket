enum FeeStatusType { paid, pending, overdue, none }

class ChildSummary {
  const ChildSummary({
    required this.childId,
    required this.childName,
    required this.schoolId,
    required this.classLabel,
    required this.attendancePercentage,
    required this.averageGradePercentage,
    required this.feeStatus,
    required this.feeRecords,
    required this.totalSessions,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  });

  final int childId;
  final String childName;
  final int schoolId;
  final String classLabel;
  final double? attendancePercentage;
  final double? averageGradePercentage;
  final FeeStatusType feeStatus;
  final int feeRecords;
  final int totalSessions;
  final int presentCount;
  final int lateCount;
  final int absentCount;

  bool get hasCriticalFeeAlert => feeStatus == FeeStatusType.overdue;
  bool get hasAnyFeeAlert =>
      feeStatus == FeeStatusType.pending || feeStatus == FeeStatusType.overdue;
}

class DashboardOverview {
  const DashboardOverview({
    required this.parentName,
    required this.children,
    required this.criticalAlerts,
  });

  final String parentName;
  final List<ChildSummary> children;
  final int criticalAlerts;
}

class ChildClassroomOverview {
  const ChildClassroomOverview({
    required this.classroomId,
    required this.classroomName,
    required this.attendancePercentage,
    required this.averageScorePercentage,
    required this.totalSessions,
  });

  final int classroomId;
  final String classroomName;
  final double? attendancePercentage;
  final double? averageScorePercentage;
  final int totalSessions;
}

class AssignmentScoreItem {
  const AssignmentScoreItem({
    required this.assignmentId,
    required this.assignmentTitle,
    required this.classroomId,
    required this.classroomName,
    required this.percentage,
    required this.score,
    required this.total,
    required this.submittedAt,
  });

  final int assignmentId;
  final String assignmentTitle;
  final int classroomId;
  final String classroomName;
  final double percentage;
  final double score;
  final int total;
  final DateTime submittedAt;
}

class FeeHistoryItem {
  const FeeHistoryItem({
    required this.id,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.paidOn,
  });

  final int id;
  final double amount;
  final DateTime dueDate;
  final FeeStatusType status;
  final DateTime? paidOn;
}

class AttendanceChartPoint {
  const AttendanceChartPoint({
    required this.classroomId,
    required this.sessionDate,
    required this.status,
    required this.classroomName,
    required this.topic,
  });

  final int classroomId;
  final DateTime sessionDate;
  final String status;
  final String classroomName;
  final String topic;
}

class SubjectPerformanceItem {
  const SubjectPerformanceItem({
    required this.subject,
    required this.averagePercentage,
  });

  final String subject;
  final double? averagePercentage;
}

class ChildDetailData {
  const ChildDetailData({
    required this.child,
    required this.classrooms,
    required this.recentAssignments,
    required this.feeHistory,
    required this.attendanceTimeline,
    required this.subjectPerformance,
  });

  final ChildSummary child;
  final List<ChildClassroomOverview> classrooms;
  final List<AssignmentScoreItem> recentAssignments;
  final List<FeeHistoryItem> feeHistory;
  final List<AttendanceChartPoint> attendanceTimeline;
  final List<SubjectPerformanceItem> subjectPerformance;
}

class SessionAttendanceItem {
  const SessionAttendanceItem({
    required this.sessionId,
    required this.sessionDate,
    required this.topic,
    required this.status,
  });

  final int sessionId;
  final DateTime sessionDate;
  final String topic;
  final String status;
}

class ClassroomDetailData {
  const ClassroomDetailData({
    required this.classroomId,
    required this.classroomName,
    required this.childId,
    required this.childName,
    required this.attendancePercentage,
    required this.averageScorePercentage,
    required this.sessions,
    required this.assignments,
  });

  final int classroomId;
  final String classroomName;
  final int childId;
  final String childName;
  final double? attendancePercentage;
  final double? averageScorePercentage;
  final List<SessionAttendanceItem> sessions;
  final List<AssignmentScoreItem> assignments;
}

class AnnouncementItem {
  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final DateTime createdAt;
}

class HolidayItem {
  const HolidayItem({
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

class MessageItem {
  const MessageItem({
    required this.id,
    required this.teacherName,
    required this.subject,
    required this.message,
    required this.reply,
    required this.status,
    required this.createdAt,
    required this.repliedAt,
  });

  final int id;
  final String teacherName;
  final String subject;
  final String message;
  final String? reply;
  final String status;
  final DateTime createdAt;
  final DateTime? repliedAt;
}

class TimetableSessionItem {
  const TimetableSessionItem({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacherName,
    required this.classroomName,
  });

  final int id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String subject;
  final String teacherName;
  final String classroomName;
}

class AssignmentTrackerItem {
  const AssignmentTrackerItem({
    required this.assignmentId,
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.isSubmitted,
    required this.status,
    this.score,
    this.total,
    this.percentage,
    this.submittedAt,
  });

  final int assignmentId;
  final String title;
  final String subject;
  final DateTime dueDate;
  final bool isSubmitted;
  final String status;
  final double? score;
  final int? total;
  final double? percentage;
  final DateTime? submittedAt;
}
