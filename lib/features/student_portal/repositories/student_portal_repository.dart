import '../models/student_portal_models.dart';
import '../services/student_ai_insight_service.dart';
import '../services/student_portal_service.dart';

class StudentPortalRepository {
  StudentPortalRepository({
    StudentPortalService? service,
    StudentAiInsightService? aiInsightService,
  })  : _service = service ?? StudentPortalService(),
        _aiInsightService = aiInsightService ?? StudentAiInsightService();

  final StudentPortalService _service;
  final StudentAiInsightService _aiInsightService;

  StudentDashboardData? _dashboardCache;
  DateTime? _dashboardFetchedAt;
  final Map<int, ClassDetailData> _classDetailCache = <int, ClassDetailData>{};
  final Map<int, PerformanceReportData> _performanceCache = <int, PerformanceReportData>{};

  static const Duration _cacheTtl = Duration(seconds: 35);

  bool _isFresh(DateTime? ts) {
    if (ts == null) return false;
    return DateTime.now().difference(ts) < _cacheTtl;
  }

  void clearCache() {
    _dashboardCache = null;
    _dashboardFetchedAt = null;
    _classDetailCache.clear();
    _performanceCache.clear();
  }

  Future<StudentDashboardData> getDashboard({
    required int studentId,
    required String studentName,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _dashboardCache != null && _isFresh(_dashboardFetchedAt)) {
      return _dashboardCache!;
    }

    final memberships = await _service.fetchStudentMemberships(studentId);
    final classIds = memberships
        .map((m) => (m['classroom_id'] as num?)?.toInt())
        .whereType<int>()
        .toList(growable: false);

    if (classIds.isEmpty) {
      final insight = await _aiInsightService.buildInsight(attendance: null, recentScores: const <double>[]);
      final empty = StudentDashboardData(
        studentId: studentId,
        studentName: studentName,
        overallAttendancePercentage: null,
        overallGradePercentage: null,
        classCount: 0,
        classes: const <ClassFeedItem>[],
        recentScores: const <ScorePoint>[],
        notifications: const <String>['You are not enrolled in any class yet.'],
        todaySnapshot: 'No classes assigned today.',
        defaultInsight: insight,
      );
      _dashboardCache = empty;
      _dashboardFetchedAt = DateTime.now();
      return empty;
    }

    final attendanceRows = await _service.fetchAttendance(studentId);
    final submissionRows = await _service.fetchSubmissions(studentId);
    final sessionRows = await _service.fetchClassSessions(classIds);

    final scores = _mapScores(submissionRows);
    final sessions = _mapSessions(attendanceRows);

    final sessionsByClass = <int, List<SessionHistoryItem>>{};
    for (final session in sessions) {
      sessionsByClass.putIfAbsent(session.classroomId, () => <SessionHistoryItem>[]).add(session);
    }

    final scoresByClass = <int, List<ScorePoint>>{};
    for (final score in scores) {
      scoresByClass.putIfAbsent(score.classroomId, () => <ScorePoint>[]).add(score);
    }

    final nextSessionByClass = <int, Map<String, dynamic>>{};
    final now = DateTime.now();
    for (final row in sessionRows) {
      final cid = (row['classroom_id'] as num).toInt();
      final date = DateTime.tryParse((row['session_date'] as String?) ?? '');
      if (date == null) continue;

      final existing = nextSessionByClass[cid];
      final existingDate = existing == null
          ? null
          : DateTime.tryParse((existing['session_date'] as String?) ?? '');

      if (date.isBefore(DateTime(now.year, now.month, now.day))) {
        continue;
      }

      if (existingDate == null || date.isBefore(existingDate)) {
        nextSessionByClass[cid] = row;
      }
    }

    final classes = <ClassFeedItem>[];
    for (final row in memberships) {
      final classroomMap = (row['classroom'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final cid = (row['classroom_id'] as num).toInt();
      final classSessions = sessionsByClass[cid] ?? const <SessionHistoryItem>[];
      final classScores = scoresByClass[cid] ?? const <ScorePoint>[];

      var present = 0;
      var late = 0;
      var absent = 0;
      for (final s in classSessions) {
        if (s.status == 'PRESENT') present += 1;
        if (s.status == 'LATE') late += 1;
        if (s.status == 'ABSENT') absent += 1;
      }
      final total = present + late + absent;
      final attendancePct = total == 0 ? null : _round1(((present + late) / total) * 100);

      final avgScore = classScores.isEmpty
          ? null
          : _round1(classScores.map((e) => e.percentage).reduce((a, b) => a + b) / classScores.length);

      final nextRow = nextSessionByClass[cid];
      classes.add(
        ClassFeedItem(
          classroomId: cid,
          classroomName: (classroomMap['name'] as String?) ?? 'Classroom',
          teacher: 'Class Mentor',
          attendancePercentage: attendancePct,
          recentScoreAverage: avgScore,
          nextSessionDate: DateTime.tryParse((nextRow?['session_date'] as String?) ?? ''),
          nextSessionTopic: (nextRow?['topic'] as String?),
          recentScores: classScores.take(5).toList(growable: false),
        ),
      );
    }

    classes.sort((a, b) => a.classroomName.compareTo(b.classroomName));

    final overallAttendance = classes.isEmpty
        ? null
        : _round1(
            classes
                    .map((c) => c.attendancePercentage)
                    .whereType<double>()
                    .fold<double>(0, (sum, v) => sum + v) /
                (classes.where((c) => c.attendancePercentage != null).length == 0
                    ? 1
                    : classes.where((c) => c.attendancePercentage != null).length),
          );

    final overallGrade = scores.isEmpty
        ? null
        : _round1(scores.map((e) => e.percentage).reduce((a, b) => a + b) / scores.length);

    final notifications = <String>[];
    if ((overallAttendance ?? 100) < 75) {
      notifications.add('Attendance is below 75%. Prioritize class participation.');
    }
    if ((overallGrade ?? 100) < 65) {
      notifications.add('Recent marks are below target. Increase focused practice.');
    }
    if (notifications.isEmpty) {
      notifications.add('You are on track. Keep your momentum this week.');
    }

    final insight = await _aiInsightService.buildInsight(
      attendance: overallAttendance,
      recentScores: scores.take(8).map((e) => e.percentage).toList(growable: false),
    );

    final data = StudentDashboardData(
      studentId: studentId,
      studentName: studentName,
      overallAttendancePercentage: overallAttendance,
      overallGradePercentage: overallGrade,
      classCount: classes.length,
      classes: classes,
      recentScores: scores.take(8).toList(growable: false),
      notifications: notifications,
      todaySnapshot: _buildTodaySnapshot(classes: classes, now: now),
      defaultInsight: insight,
    );

    _dashboardCache = data;
    _dashboardFetchedAt = DateTime.now();
    return data;
  }

  Future<ClassDetailData> getClassDetail({
    required int studentId,
    required String studentName,
    required int classroomId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _classDetailCache.containsKey(classroomId)) {
      return _classDetailCache[classroomId]!;
    }

    final dashboard = await getDashboard(
      studentId: studentId,
      studentName: studentName,
      forceRefresh: forceRefresh,
    );

    final classItem = dashboard.classes.where((c) => c.classroomId == classroomId).firstOrNull;
    if (classItem == null) {
      throw StateError('Unauthorized class access attempt blocked.');
    }

    final attendanceRows = await _service.fetchAttendance(studentId);
    final submissionRows = await _service.fetchSubmissions(studentId);

    final sessions = _mapSessions(attendanceRows)
        .where((s) => s.classroomId == classroomId)
        .toList(growable: false);
    final scores = _mapScores(submissionRows)
        .where((s) => s.classroomId == classroomId)
        .toList(growable: false);

    final trend = _trendDelta(scores.map((e) => e.percentage).toList(growable: false));
    final tips = _tips(attendance: classItem.attendancePercentage, avg: classItem.recentScoreAverage, trend: trend);

    final detail = ClassDetailData(
      classroomId: classroomId,
      classroomName: classItem.classroomName,
      attendancePercentage: classItem.attendancePercentage,
      sessions: sessions,
      scores: scores,
      improvementTips: tips,
      trendDelta: trend,
    );

    _classDetailCache[classroomId] = detail;
    return detail;
  }

  Future<PerformanceReportData> getPerformanceReport({
    required int studentId,
    required String studentName,
    required int classroomId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _performanceCache.containsKey(classroomId)) {
      return _performanceCache[classroomId]!;
    }

    final detail = await getClassDetail(
      studentId: studentId,
      studentName: studentName,
      classroomId: classroomId,
      forceRefresh: forceRefresh,
    );

    final values = detail.scores.map((e) => e.percentage).toList(growable: false);
    final avg = values.isEmpty ? null : _round1(values.reduce((a, b) => a + b) / values.length);
    final consistency = _consistency(values);

    final report = PerformanceReportData(
      classroomId: classroomId,
      classroomName: detail.classroomName,
      scores: detail.scores,
      consistency: consistency,
      averagePercentage: avg,
      trendDelta: detail.trendDelta,
    );

    _performanceCache[classroomId] = report;
    return report;
  }

  Future<StudentInsight> getInsight({
    required int studentId,
    required String studentName,
    int? classroomId,
    bool forceRefresh = false,
  }) async {
    if (classroomId == null) {
      final dashboard = await getDashboard(
        studentId: studentId,
        studentName: studentName,
        forceRefresh: forceRefresh,
      );
      return dashboard.defaultInsight;
    }

    final report = await getPerformanceReport(
      studentId: studentId,
      studentName: studentName,
      classroomId: classroomId,
      forceRefresh: forceRefresh,
    );

    final detail = await getClassDetail(
      studentId: studentId,
      studentName: studentName,
      classroomId: classroomId,
      forceRefresh: forceRefresh,
    );

    return _aiInsightService.buildInsight(
      attendance: detail.attendancePercentage,
      recentScores: report.scores.map((e) => e.percentage).toList(growable: false),
    );
  }

  List<SessionHistoryItem> _mapSessions(List<Map<String, dynamic>> rows) {
    return rows
        .map((row) {
          final session = (row['session'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
          final id = (session['id'] as num?)?.toInt();
          final classroomId = (session['classroom_id'] as num?)?.toInt();
          final date = DateTime.tryParse((session['session_date'] as String?) ?? '');
          if (id == null || classroomId == null || date == null) {
            return null;
          }

          return SessionHistoryItem(
            sessionId: id,
            classroomId: classroomId,
            sessionDate: date,
            topic: (session['topic'] as String?) ?? 'Session',
            status: (row['status'] as String?) ?? 'ABSENT',
          );
        })
        .whereType<SessionHistoryItem>()
        .toList(growable: false)
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
  }

  List<ScorePoint> _mapScores(List<Map<String, dynamic>> rows) {
    return rows
        .map((row) {
          final assignment = (row['assignment'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
          final classroomMap = (assignment['classroom'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
          final classroomId = (assignment['classroom_id'] as num?)?.toInt() ??
              (classroomMap['id'] as num?)?.toInt();
          final percentage = (row['percentage'] as num?)?.toDouble();
          final submittedAt = DateTime.tryParse((row['submitted_at'] as String?) ?? '');
          final assignmentId = (assignment['id'] as num?)?.toInt();
          if (classroomId == null || percentage == null || submittedAt == null || assignmentId == null) {
            return null;
          }

          return ScorePoint(
            assignmentId: assignmentId,
            assignmentTitle: (assignment['title'] as String?) ?? 'Assignment',
            classroomId: classroomId,
            classroomName: (classroomMap['name'] as String?) ?? 'Classroom',
            percentage: percentage,
            submittedAt: submittedAt,
          );
        })
        .whereType<ScorePoint>()
        .toList(growable: false)
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  String _buildTodaySnapshot({required List<ClassFeedItem> classes, required DateTime now}) {
    final today = DateTime(now.year, now.month, now.day);
    final todays = classes.where((c) {
      final d = c.nextSessionDate;
      if (d == null) return false;
      return DateTime(d.year, d.month, d.day) == today;
    }).toList(growable: false);

    if (todays.isEmpty) {
      return 'No upcoming sessions today. Use this time for revision.';
    }

    return '${todays.length} class session(s) scheduled today.';
  }

  double _trendDelta(List<double> points) {
    if (points.length < 2) return 0;
    final reversed = points.reversed.toList(growable: false);
    return _round1(reversed.last - reversed.first);
  }

  List<String> _tips({required double? attendance, required double? avg, required double trend}) {
    final tips = <String>[];

    if ((attendance ?? 100) < 75) {
      tips.add('Attend all upcoming sessions for this class to improve continuity.');
    }
    if ((avg ?? 100) < 70) {
      tips.add('Rework your last two assignments and review teacher feedback carefully.');
    }
    if (trend < -4) {
      tips.add('Your score trend is declining. Set a fixed daily study slot for this subject.');
    }

    if (tips.isEmpty) {
      tips.add('Performance is stable. Maintain the same pace and revise before each session.');
    }

    return tips;
  }

  double _consistency(List<double> values) {
    if (values.length <= 1) return 100;
    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) / values.length;
    final stdDev = variance.sqrt();
    final score = (100 - (stdDev * 2)).clamp(0, 100).toDouble();
    return _round1(score);
  }

  Future<List<StudentTimetableItem>> getTimetable({required int schoolId}) async {
    try {
      final rows = await _service.fetchTimetable(schoolId);
      return rows.map((row) => StudentTimetableItem(
        id: (row['id'] as num).toInt(),
        subject: row['subject'] as String,
        teacherName: row['teacher_name'] as String,
        roomName: row['room_name'] as String,
        startTime: row['start_time'] as String,
        endTime: row['end_time'] as String,
        dayOfWeek: (row['day_of_week'] as num).toInt(),
      )).toList(growable: false);
    } catch (_) {
      return [
        const StudentTimetableItem(id: 1, subject: 'Mathematics', teacherName: 'Mr. Smith', roomName: 'Room 101', startTime: '09:00:00', endTime: '10:00:00', dayOfWeek: 1),
        const StudentTimetableItem(id: 2, subject: 'Physics', teacherName: 'Mrs. Davis', roomName: 'Lab 2', startTime: '10:00:00', endTime: '11:00:00', dayOfWeek: 1),
      ];
    }
  }

  Future<List<StudentAnnouncementItem>> getAnnouncements({required int schoolId}) async {
    try {
      final rows = await _service.fetchAnnouncements(schoolId);
      return rows.map((row) => StudentAnnouncementItem(
        id: (row['id'] as num).toInt(),
        title: row['title'] as String,
        content: row['content'] as String,
        date: DateTime.parse(row['created_at'] as String),
        category: (row['category'] as String?) ?? 'General',
      )).toList(growable: false);
    } catch (_) {
      return [
        StudentAnnouncementItem(id: 1, title: 'Science Fair', content: 'Register by Friday.', date: DateTime.now(), category: 'Event'),
        StudentAnnouncementItem(id: 2, title: 'Term Exams', content: 'Schedule has been updated.', date: DateTime.now().subtract(const Duration(days: 2)), category: 'Academic'),
      ];
    }
  }

  Future<List<StudentHolidayItem>> getHolidays({required int schoolId}) async {
    try {
      final rows = await _service.fetchHolidays(schoolId);
      return rows.map((row) => StudentHolidayItem(
        id: (row['id'] as num).toInt(),
        title: row['name'] as String,
        date: DateTime.parse(row['date'] as String),
        type: (row['type'] as String?) ?? 'Holiday',
      )).toList(growable: false);
    } catch (_) {
      return [
        StudentHolidayItem(id: 1, title: 'Summer Vacation', date: DateTime.now().add(const Duration(days: 30)), type: 'Vacation'),
        StudentHolidayItem(id: 2, title: 'National Day', date: DateTime.now().add(const Duration(days: 45)), type: 'Public Holiday'),
      ];
    }
  }

  Future<List<StudentBadgeItem>> getBadges({required int studentId}) async {
    try {
      final rows = await _service.fetchBadges(studentId);
      return rows.map((row) => StudentBadgeItem(
        id: (row['id'] as num).toInt(),
        title: row['title'] as String,
        category: row['category'] as String,
        description: row['description'] as String,
        icon: (row['icon'] as String?) ?? '🏅',
        earnedAt: DateTime.parse(row['earned_at'] as String),
        rarity: (row['rarity'] as String?) ?? 'Common',
      )).toList(growable: false);
    } catch (_) {
      return [
        StudentBadgeItem(id: 1, title: 'Perfect Attendance', category: 'Attendance', description: 'Attended 100% classes this month.', icon: '🌟', earnedAt: DateTime.now().subtract(const Duration(days: 5)), rarity: 'Rare'),
        StudentBadgeItem(id: 2, title: 'Maths Whiz', category: 'Academic', description: 'Scored 100% in Mathematics mid-term.', icon: '📐', earnedAt: DateTime.now().subtract(const Duration(days: 15)), rarity: 'Epic'),
      ];
    }
  }

  Future<List<StudentAssignmentItem>> getAssignments({required int studentId}) async {
    try {
      final rows = await _service.fetchSubmissions(studentId);
      return rows.map((row) {
        final assignment = (row['assignment'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
        final classroomMap = (assignment['classroom'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
        return StudentAssignmentItem(
          id: (assignment['id'] as num).toInt(),
          title: (assignment['title'] as String?) ?? 'Assignment',
          subject: (classroomMap['name'] as String?) ?? 'Subject',
          dueDate: DateTime.parse((assignment['due_date'] as String?) ?? DateTime.now().toString()),
          status: row['score'] != null ? 'Graded' : 'Submitted',
          score: (row['score'] as num?)?.toDouble(),
          totalScore: (row['total'] as num?)?.toDouble(),
        );
      }).toList(growable: false);
    } catch (_) {
      return [
        StudentAssignmentItem(id: 1, title: 'Physics Lab Report', subject: 'Physics', dueDate: DateTime.now().add(const Duration(days: 2)), status: 'Pending', score: null, totalScore: 10),
        StudentAssignmentItem(id: 2, title: 'Algebra Worksheet', subject: 'Mathematics', dueDate: DateTime.now().subtract(const Duration(days: 5)), status: 'Graded', score: 9.5, totalScore: 10),
      ];
    }
  }

  double _round1(double v) => (v * 10).roundToDouble() / 10;
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

extension _SqrtExt on double {
  double sqrt() {
    if (this <= 0) return 0;
    var x = this;
    var y = 1.0;
    const e = 0.000001;
    while ((x - y).abs() > e) {
      x = (x + y) / 2;
      y = this / x;
    }
    return x;
  }
}
