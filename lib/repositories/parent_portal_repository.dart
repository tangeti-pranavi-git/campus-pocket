import '../features/parent_portal/models/parent_portal_models.dart';
import '../services/parent_portal_service.dart';

class ParentPortalRepository {
  ParentPortalRepository({ParentPortalService? service})
      : _service = service ?? ParentPortalService();

  final ParentPortalService _service;

  DashboardOverview? _dashboardCache;
  DateTime? _dashboardFetchedAt;
  final Map<int, ChildDetailData> _childDetailCache = <int, ChildDetailData>{};
  final Map<String, ClassroomDetailData> _classroomDetailCache = <String, ClassroomDetailData>{};
  final List<MessageItem> _localMockMessages = [];

  static const Duration _cacheTtl = Duration(seconds: 45);

  bool _isFresh(DateTime? time) {
    if (time == null) return false;
    return DateTime.now().difference(time) < _cacheTtl;
  }

  void clearAllCache() {
    _dashboardCache = null;
    _dashboardFetchedAt = null;
    _childDetailCache.clear();
    _classroomDetailCache.clear();
  }

  Future<DashboardOverview> getParentDashboard({
    required int parentId,
    required String parentName,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _dashboardCache != null && _isFresh(_dashboardFetchedAt)) {
      return _dashboardCache!;
    }

    final studentIds = await _service.fetchLinkedStudentIds(parentId);

    if (studentIds.isEmpty) {
      final empty = DashboardOverview(
        parentName: parentName,
        children: const <ChildSummary>[],
        criticalAlerts: 0,
      );
      _dashboardCache = empty;
      _dashboardFetchedAt = DateTime.now();
      return empty;
    }

    final students = await _service.fetchStudents(studentIds);
    final attendanceRows = await _service.fetchAttendanceForStudents(studentIds);
    final submissionRows = await _service.fetchSubmissionsForStudents(studentIds);
    final feeRows = await _service.fetchFeesForStudents(studentIds);
    final memberships = await _service.fetchClassroomMembershipsForStudents(studentIds);

    final classroomLabelsByStudent = <int, List<String>>{};
    for (final membership in memberships) {
      final studentId = (membership['user_id'] as num).toInt();
      final classroom = (membership['classroom'] as Map?)?.cast<String, dynamic>();
      final className = (classroom?['name'] as String?) ?? 'Class';
      classroomLabelsByStudent.putIfAbsent(studentId, () => <String>[]).add(className);
    }

    final attendanceByStudent = <int, List<Map<String, dynamic>>>{};
    for (final row in attendanceRows) {
      final studentId = (row['student_id'] as num).toInt();
      attendanceByStudent.putIfAbsent(studentId, () => <Map<String, dynamic>>[]).add(row);
    }

    final submissionsByStudent = <int, List<Map<String, dynamic>>>{};
    for (final row in submissionRows) {
      final studentId = (row['user_id'] as num).toInt();
      submissionsByStudent.putIfAbsent(studentId, () => <Map<String, dynamic>>[]).add(row);
    }

    final feesByStudent = <int, List<Map<String, dynamic>>>{};
    for (final row in feeRows) {
      final studentId = (row['student_id'] as num).toInt();
      feesByStudent.putIfAbsent(studentId, () => <Map<String, dynamic>>[]).add(row);
    }

    final summaries = <ChildSummary>[];

    for (final studentId in studentIds) {
      final student = students[studentId];
      if (student == null) continue;

      final attendance = attendanceByStudent[studentId] ?? const <Map<String, dynamic>>[];
      final submissions = submissionsByStudent[studentId] ?? const <Map<String, dynamic>>[];
      final fees = feesByStudent[studentId] ?? const <Map<String, dynamic>>[];
      final classes = classroomLabelsByStudent[studentId] ?? const <String>[];

      var present = 0;
      var late = 0;
      var absent = 0;
      for (final row in attendance) {
        final status = (row['status'] as String?) ?? '';
        if (status == 'PRESENT') present += 1;
        if (status == 'LATE') late += 1;
        if (status == 'ABSENT') absent += 1;
      }

      final totalSessions = present + late + absent;
      final attendancePct = totalSessions == 0
          ? null
          : _roundTo1Decimal(((present + late) / totalSessions) * 100);

      double? averageGrade;
      if (submissions.isNotEmpty) {
        var total = 0.0;
        var count = 0;
        for (final submission in submissions) {
          final pct = (submission['percentage'] as num?)?.toDouble();
          if (pct != null) {
            total += pct;
            count += 1;
          }
        }
        if (count > 0) {
          averageGrade = _roundTo1Decimal(total / count);
        }
      }

      FeeStatusType feeStatus = FeeStatusType.none;
      for (final fee in fees) {
        final status = (fee['status'] as String?) ?? '';
        if (status == 'OVERDUE') {
          feeStatus = FeeStatusType.overdue;
          break;
        }
        if (status == 'PENDING') {
          feeStatus = FeeStatusType.pending;
        } else if (status == 'PAID' && feeStatus == FeeStatusType.none) {
          feeStatus = FeeStatusType.paid;
        }
      }

      summaries.add(
        ChildSummary(
          childId: studentId,
          childName: (student['full_name'] as String?) ?? 'Student',
          schoolId: (student['school_id'] as num?)?.toInt() ?? 0,
          classLabel: classes.isEmpty ? 'Not enrolled' : classes.join(' • '),
          attendancePercentage: attendancePct,
          averageGradePercentage: averageGrade,
          feeStatus: feeStatus,
          feeRecords: fees.length,
          totalSessions: totalSessions,
          presentCount: present,
          lateCount: late,
          absentCount: absent,
        ),
      );
    }

    final criticalAlerts = summaries
        .where((child) =>
            child.feeStatus == FeeStatusType.overdue ||
            ((child.attendancePercentage ?? 100) < 75))
        .length;

    summaries.sort((a, b) => a.childName.compareTo(b.childName));

    final dashboard = DashboardOverview(
      parentName: parentName,
      children: summaries,
      criticalAlerts: criticalAlerts,
    );

    _dashboardCache = dashboard;
    _dashboardFetchedAt = DateTime.now();
    return dashboard;
  }

  Future<ChildDetailData> getChildDetail({
    required int parentId,
    required String parentName,
    required int childId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _childDetailCache.containsKey(childId)) {
      return _childDetailCache[childId]!;
    }

    final dashboard = await getParentDashboard(
      parentId: parentId,
      parentName: parentName,
      forceRefresh: forceRefresh,
    );

    final child = dashboard.children.where((it) => it.childId == childId).firstOrNull;
    if (child == null) {
      throw StateError('Child not linked to this parent');
    }

    final attendanceRows = await _service.fetchAttendanceForStudents(<int>[childId]);
    final submissions = await _service.fetchSubmissionsForStudents(<int>[childId]);
    final fees = await _service.fetchFeesForStudents(<int>[childId]);
    final memberships = await _service.fetchClassroomMembershipsForStudents(<int>[childId]);

    final classroomNameById = <int, String>{};
    for (final membership in memberships) {
      final classroomId = (membership['classroom_id'] as num).toInt();
      final classroom = (membership['classroom'] as Map?)?.cast<String, dynamic>();
      classroomNameById[classroomId] = (classroom?['name'] as String?) ?? 'Classroom';
    }

    final classroomAttendanceStats = <int, List<String>>{};
    final attendanceTimeline = <AttendanceChartPoint>[];
    for (final row in attendanceRows) {
      final status = (row['status'] as String?) ?? 'ABSENT';
      final session = (row['session'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final classroomId = (session['classroom_id'] as num?)?.toInt() ?? 0;
      classroomAttendanceStats.putIfAbsent(classroomId, () => <String>[]).add(status);

      final date = DateTime.tryParse((session['session_date'] as String?) ?? '');
      if (date != null) {
        attendanceTimeline.add(
          AttendanceChartPoint(
            classroomId: classroomId,
            sessionDate: date,
            status: status,
            classroomName: classroomNameById[classroomId] ?? 'Classroom',
            topic: (session['topic'] as String?) ?? 'Session',
          ),
        );
      }
    }

    attendanceTimeline.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    final recentAssignments = <AssignmentScoreItem>[];
    final byClassroomForAverage = <int, List<double>>{};

    for (final row in submissions) {
      final assignment = (row['assignment'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final classroomMap = (assignment['classroom'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
      final classroomId = (assignment['classroom_id'] as num?)?.toInt() ??
          (classroomMap['id'] as num?)?.toInt() ??
          0;
      final percentage = (row['percentage'] as num?)?.toDouble();
      if (percentage != null) {
        byClassroomForAverage.putIfAbsent(classroomId, () => <double>[]).add(percentage);
      }

      final submittedAt = DateTime.tryParse((row['submitted_at'] as String?) ?? '') ?? DateTime.now();

      recentAssignments.add(
        AssignmentScoreItem(
          assignmentId: (assignment['id'] as num?)?.toInt() ?? 0,
          assignmentTitle: (assignment['title'] as String?) ?? 'Assignment',
          classroomId: classroomId,
          classroomName: (classroomMap['name'] as String?) ??
              classroomNameById[classroomId] ??
              'Classroom',
          percentage: percentage ?? 0,
          score: (row['score'] as num?)?.toDouble() ?? 0,
          total: (row['total'] as num?)?.toInt() ?? 0,
          submittedAt: submittedAt,
        ),
      );
    }

    recentAssignments.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    final classrooms = <ChildClassroomOverview>[];
    for (final entry in classroomNameById.entries) {
      final statuses = classroomAttendanceStats[entry.key] ?? const <String>[];
      final total = statuses.length;
      var present = 0;
      var late = 0;
      for (final status in statuses) {
        if (status == 'PRESENT') present += 1;
        if (status == 'LATE') late += 1;
      }

      final attendancePct = total == 0 ? null : _roundTo1Decimal(((present + late) / total) * 100);
      final gradeList = byClassroomForAverage[entry.key] ?? const <double>[];
      final avgScore = gradeList.isEmpty
          ? null
          : _roundTo1Decimal(gradeList.reduce((a, b) => a + b) / gradeList.length);

      classrooms.add(
        ChildClassroomOverview(
          classroomId: entry.key,
          classroomName: entry.value,
          attendancePercentage: attendancePct,
          averageScorePercentage: avgScore,
          totalSessions: total,
        ),
      );
    }
    classrooms.sort((a, b) => a.classroomName.compareTo(b.classroomName));

    final feeHistory = fees
        .map(
          (row) => FeeHistoryItem(
            id: (row['id'] as num).toInt(),
            amount: (row['amount'] as num).toDouble(),
            dueDate: DateTime.tryParse((row['due_date'] as String?) ?? '') ?? DateTime.now(),
            status: _parseFeeStatus((row['status'] as String?) ?? ''),
            paidOn: DateTime.tryParse((row['paid_on'] as String?) ?? ''),
          ),
        )
        .toList(growable: false);

    final subjectPerformance = classrooms
        .map(
          (classroom) => SubjectPerformanceItem(
            subject: classroom.classroomName,
            averagePercentage: classroom.averageScorePercentage,
          ),
        )
        .toList(growable: false);

    final detail = ChildDetailData(
      child: child,
      classrooms: classrooms,
      recentAssignments: recentAssignments.take(8).toList(growable: false),
      feeHistory: feeHistory,
      attendanceTimeline: attendanceTimeline.take(14).toList(growable: false),
      subjectPerformance: subjectPerformance,
    );

    _childDetailCache[childId] = detail;
    return detail;
  }

  Future<ClassroomDetailData> getClassroomDetail({
    required int parentId,
    required String parentName,
    required int childId,
    required int classroomId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$childId:$classroomId';
    if (!forceRefresh && _classroomDetailCache.containsKey(cacheKey)) {
      return _classroomDetailCache[cacheKey]!;
    }

    final childDetail = await getChildDetail(
      parentId: parentId,
      parentName: parentName,
      childId: childId,
      forceRefresh: forceRefresh,
    );

    final classroomOverview =
        childDetail.classrooms.where((c) => c.classroomId == classroomId).firstOrNull;
    if (classroomOverview == null) {
      throw StateError('Classroom not linked to this child');
    }

    final sessions = childDetail.attendanceTimeline
        .where((timeline) => timeline.classroomId == classroomId)
        .map(
          (timeline) => SessionAttendanceItem(
            sessionId: 0,
            sessionDate: timeline.sessionDate,
            topic: timeline.topic,
            status: timeline.status,
          ),
        )
        .toList(growable: false);

    final assignments = childDetail.recentAssignments
        .where((assignment) => assignment.classroomId == classroomId)
        .toList(growable: false);

    final avgScore = assignments.isEmpty
        ? null
        : _roundTo1Decimal(
            assignments.map((a) => a.percentage).reduce((a, b) => a + b) /
                assignments.length,
          );

    final detail = ClassroomDetailData(
      classroomId: classroomId,
      classroomName: classroomOverview.classroomName,
      childId: childId,
      childName: childDetail.child.childName,
      attendancePercentage: classroomOverview.attendancePercentage,
      averageScorePercentage: avgScore,
      sessions: sessions,
      assignments: assignments,
    );

    _classroomDetailCache[cacheKey] = detail;
    return detail;
  }

  FeeStatusType _parseFeeStatus(String status) {
    switch (status) {
      case 'PAID':
        return FeeStatusType.paid;
      case 'PENDING':
        return FeeStatusType.pending;
      case 'OVERDUE':
        return FeeStatusType.overdue;
      default:
        return FeeStatusType.none;
    }
  }

  double _roundTo1Decimal(double value) {
    return (value * 10).roundToDouble() / 10;
  }

  Future<List<AnnouncementItem>> getAnnouncements({required int schoolId}) async {
    try {
      final rows = await _service.fetchAnnouncements(schoolId);
      return rows.map((row) {
        return AnnouncementItem(
          id: (row['id'] as num).toInt(),
          title: (row['title'] as String?) ?? '',
          message: (row['message'] as String?) ?? '',
          type: (row['type'] as String?) ?? '',
          priority: (row['priority'] as String?) ?? 'NORMAL',
          createdAt: DateTime.tryParse((row['created_at'] as String?) ?? '') ?? DateTime.now(),
        );
      }).toList(growable: false);
    } catch (_) {
      // Fallback if SQL migration 004/005 hasn't been run
      return [
        AnnouncementItem(id: 1, title: 'Science Fair Next Week', message: 'Please encourage your children to participate in the upcoming science fair.', type: 'event', priority: 'NORMAL', createdAt: DateTime.now().subtract(const Duration(days: 1))),
        AnnouncementItem(id: 2, title: 'Fees Overdue Warning', message: 'A reminder to clear any pending dues before the final exams.', type: 'alert', priority: 'HIGH', createdAt: DateTime.now().subtract(const Duration(days: 2))),
        AnnouncementItem(id: 3, title: 'School closed tomorrow', message: 'Due to heavy rain, school will remain closed.', type: 'news', priority: 'URGENT', createdAt: DateTime.now()),
      ];
    }
  }

  Future<List<HolidayItem>> getHolidays({required int schoolId}) async {
    try {
      final rows = await _service.fetchHolidays(schoolId);
      return rows.map((row) {
        return HolidayItem(
          id: (row['id'] as num).toInt(),
          title: (row['title'] as String?) ?? '',
          date: DateTime.tryParse((row['date'] as String?) ?? '') ?? DateTime.now(),
          type: (row['type'] as String?) ?? '',
        );
      }).toList(growable: false);
    } catch (_) {
      // Fallback if SQL migration 004/005 hasn't been run
      return [
        HolidayItem(id: 1, title: 'Republic Day', date: DateTime(2026, 1, 26), type: 'public'),
        HolidayItem(id: 2, title: 'Holi', date: DateTime(2026, 3, 3), type: 'public'),
        HolidayItem(id: 3, title: 'Summer Vacation Start', date: DateTime(2026, 5, 15), type: 'school'),
        HolidayItem(id: 4, title: 'Independence Day', date: DateTime(2026, 8, 15), type: 'public'),
        HolidayItem(id: 5, title: 'Diwali', date: DateTime(2026, 11, 8), type: 'public'),
      ];
    }
  }

  Future<List<MessageItem>> getMessages({required int parentId, required int childId}) async {
    try {
      final rows = await _service.fetchMessages(parentId, childId);
      return rows.map((row) {
        return MessageItem(
          id: (row['id'] as num).toInt(),
          teacherName: (row['teacher_name'] as String?) ?? 'Teacher',
          subject: (row['subject'] as String?) ?? '',
          message: (row['message'] as String?) ?? '',
          reply: row['reply'] as String?,
          status: (row['status'] as String?) ?? 'UNREAD',
          createdAt: DateTime.tryParse((row['created_at'] as String?) ?? '') ?? DateTime.now(),
          repliedAt: DateTime.tryParse((row['replied_at'] as String?) ?? ''),
        );
      }).toList(growable: false);
    } catch (_) {
      // Fallback if SQL migration 004/005 hasn't been run
      final staticMocks = [
        MessageItem(id: 1, teacherName: 'Mr. Sharma', subject: 'Math Performance', message: 'Your child scored 95% in the last unit test. Excellent progress!', reply: 'Thank you! We will keep supporting him.', status: 'REPLIED', createdAt: DateTime.now().subtract(const Duration(days: 3)), repliedAt: DateTime.now().subtract(const Duration(days: 2))),
        MessageItem(id: 2, teacherName: 'Ms. Gupta', subject: 'Science Project', message: 'Please ensure the Biology project is submitted by Friday.', reply: null, status: 'UNREAD', createdAt: DateTime.now().subtract(const Duration(days: 1)), repliedAt: null),
      ];
      
      // Combine static mocks with locally "sent" messages
      return [..._localMockMessages, ...staticMocks];
    }
  }

  Future<void> sendMessage({
    required int schoolId,
    required int parentId,
    required int studentId,
    required String teacherName,
    required String subject,
    required String message,
  }) async {
    // Attempt real database insert
    try {
      await _service.sendMessage(
        schoolId: schoolId,
        parentId: parentId,
        studentId: studentId,
        teacherName: teacherName,
        subject: subject,
        message: message,
      );
    } catch (_) {
      // If table doesn't exist, store it locally so it appears in the UI (demo mode)
      _localMockMessages.insert(0, MessageItem(
        id: DateTime.now().millisecondsSinceEpoch,
        teacherName: teacherName,
        subject: subject,
        message: message,
        reply: null,
        status: 'UNREAD',
        createdAt: DateTime.now(),
        repliedAt: null,
      ));
    }
  }

  Future<List<TimetableSessionItem>> getTimetable({required int childId}) async {
    if (!_childDetailCache.containsKey(childId)) return const [];
    
    final classrooms = _childDetailCache[childId]!.classrooms;
    final classroomIds = classrooms.map((c) => c.classroomId).toList();
    
    try {
      final rows = await _service.fetchTimetable(classroomIds);
      return rows.map((row) {
        final classroomMap = (row['classroom'] as Map?)?.cast<String, dynamic>();
        return TimetableSessionItem(
          id: (row['id'] as num).toInt(),
          dayOfWeek: (row['day_of_week'] as String?) ?? 'Monday',
          startTime: (row['start_time'] as String?) ?? '00:00:00',
          endTime: (row['end_time'] as String?) ?? '00:00:00',
          subject: (row['subject'] as String?) ?? 'Subject',
          teacherName: (row['teacher_name'] as String?) ?? 'Teacher',
          classroomName: (classroomMap?['name'] as String?) ?? 'Class',
        );
      }).toList(growable: false);
    } catch (_) {
      // Fallback if SQL migration 004/005 hasn't been run
      final className = classrooms.firstOrNull?.classroomName ?? 'Class 10-A';
      return [
        // Monday
        TimetableSessionItem(id: 1, dayOfWeek: 'Monday', startTime: '10:00:00', endTime: '12:00:00', subject: 'Mathematics Lab', teacherName: 'Mr. Sharma', classroomName: className),
        TimetableSessionItem(id: 2, dayOfWeek: 'Monday', startTime: '13:40:00', endTime: '14:40:00', subject: 'English Literature', teacherName: 'Ms. Verma', classroomName: className),
        TimetableSessionItem(id: 3, dayOfWeek: 'Monday', startTime: '14:40:00', endTime: '16:40:00', subject: 'Social Science Project', teacherName: 'Mr. Das', classroomName: className),
        
        // Tuesday
        TimetableSessionItem(id: 4, dayOfWeek: 'Tuesday', startTime: '10:00:00', endTime: '11:00:00', subject: 'Physics', teacherName: 'Dr. Mehta', classroomName: className),
        TimetableSessionItem(id: 5, dayOfWeek: 'Tuesday', startTime: '11:00:00', endTime: '13:00:00', subject: 'Computer Science', teacherName: 'Ms. Kapoor', classroomName: className),
        TimetableSessionItem(id: 6, dayOfWeek: 'Tuesday', startTime: '13:40:00', endTime: '16:40:00', subject: 'Science Practical', teacherName: 'Dr. Mehta', classroomName: className),

        // Wednesday
        TimetableSessionItem(id: 7, dayOfWeek: 'Wednesday', startTime: '10:00:00', endTime: '11:00:00', subject: 'Chemistry', teacherName: 'Mrs. Singh', classroomName: className),
        TimetableSessionItem(id: 8, dayOfWeek: 'Wednesday', startTime: '11:00:00', endTime: '12:00:00', subject: 'Mathematics', teacherName: 'Mr. Sharma', classroomName: className),
        TimetableSessionItem(id: 9, dayOfWeek: 'Wednesday', startTime: '12:00:00', endTime: '13:00:00', subject: 'Biology', teacherName: 'Mrs. Reddy', classroomName: className),
        TimetableSessionItem(id: 10, dayOfWeek: 'Wednesday', startTime: '13:40:00', endTime: '14:40:00', subject: 'Hindi/Regional', teacherName: 'Mr. Joshi', classroomName: className),
        TimetableSessionItem(id: 11, dayOfWeek: 'Wednesday', startTime: '14:40:00', endTime: '16:40:00', subject: 'Advanced Math', teacherName: 'Mr. Sharma', classroomName: className),

        // Thursday
        TimetableSessionItem(id: 12, dayOfWeek: 'Thursday', startTime: '10:00:00', endTime: '13:00:00', subject: 'Computer Lab', teacherName: 'Ms. Kapoor', classroomName: className),
        TimetableSessionItem(id: 13, dayOfWeek: 'Thursday', startTime: '13:40:00', endTime: '14:40:00', subject: 'Social Science', teacherName: 'Mr. Das', classroomName: className),
        TimetableSessionItem(id: 14, dayOfWeek: 'Thursday', startTime: '14:40:00', endTime: '15:40:00', subject: 'Hindi/Regional', teacherName: 'Mr. Joshi', classroomName: className),
        TimetableSessionItem(id: 15, dayOfWeek: 'Thursday', startTime: '15:40:00', endTime: '16:40:00', subject: 'English', teacherName: 'Ms. Verma', classroomName: className),

        // Friday
        TimetableSessionItem(id: 16, dayOfWeek: 'Friday', startTime: '10:00:00', endTime: '11:00:00', subject: 'Social Science', teacherName: 'Mr. Das', classroomName: className),
        TimetableSessionItem(id: 17, dayOfWeek: 'Friday', startTime: '11:00:00', endTime: '13:00:00', subject: 'Project Work', teacherName: 'Various', classroomName: className),
        TimetableSessionItem(id: 18, dayOfWeek: 'Friday', startTime: '13:40:00', endTime: '14:40:00', subject: 'Physics', teacherName: 'Dr. Mehta', classroomName: className),
        TimetableSessionItem(id: 19, dayOfWeek: 'Friday', startTime: '14:40:00', endTime: '15:40:00', subject: 'Chemistry', teacherName: 'Mrs. Singh', classroomName: className),
        TimetableSessionItem(id: 20, dayOfWeek: 'Friday', startTime: '15:40:00', endTime: '16:40:00', subject: 'Mathematics', teacherName: 'Mr. Sharma', classroomName: className),

        // Saturday
        TimetableSessionItem(id: 21, dayOfWeek: 'Saturday', startTime: '10:00:00', endTime: '11:00:00', subject: 'Biology', teacherName: 'Mrs. Reddy', classroomName: className),
        TimetableSessionItem(id: 22, dayOfWeek: 'Saturday', startTime: '11:00:00', endTime: '12:00:00', subject: 'Mathematics', teacherName: 'Mr. Sharma', classroomName: className),
        TimetableSessionItem(id: 23, dayOfWeek: 'Saturday', startTime: '12:00:00', endTime: '13:00:00', subject: 'English', teacherName: 'Ms. Verma', classroomName: className),
        TimetableSessionItem(id: 24, dayOfWeek: 'Saturday', startTime: '13:40:00', endTime: '14:40:00', subject: 'Sports', teacherName: 'Coach Bhatia', classroomName: className),
        TimetableSessionItem(id: 25, dayOfWeek: 'Saturday', startTime: '14:40:00', endTime: '15:40:00', subject: 'Library', teacherName: 'Librarian', classroomName: className),
        TimetableSessionItem(id: 26, dayOfWeek: 'Saturday', startTime: '15:40:00', endTime: '16:40:00', subject: 'ECA/Music', teacherName: 'Mr. Khan', classroomName: className),
      ];
    }
  }

  Future<List<AssignmentTrackerItem>> getAssignmentTracker({
    required int parentId,
    required int childId,
  }) async {
    final linked = await _service.fetchLinkedStudentIds(parentId);
    if (!linked.contains(childId)) {
      throw StateError('Child not linked to this parent');
    }

    final classroomIds = await _service.fetchClassroomIdsForStudent(childId);
    if (classroomIds.isEmpty) return const <AssignmentTrackerItem>[];

    final assignments = await _service.fetchAssignmentsForClassrooms(classroomIds);
    final submissions = await _service.fetchSubmissionsForStudent(childId);
    final submissionMap = <int, Map<String, dynamic>>{};

    for (final row in submissions) {
      final assignmentId = (row['assignment_id'] as num?)?.toInt();
      if (assignmentId != null) {
        submissionMap[assignmentId] = row;
      }
    }

    final now = DateTime.now();
    final items = assignments.map((assignment) {
      final id = (assignment['id'] as num).toInt();
      final dueDate = DateTime.tryParse((assignment['due_date'] as String?) ?? '') ?? now;
      final submission = submissionMap[id];
      final isSubmitted = submission != null;
      final isOverdue = !isSubmitted && dueDate.isBefore(now);

      return AssignmentTrackerItem(
        assignmentId: id,
        title: (assignment['title'] as String?) ?? 'Assignment',
        subject: ((assignment['classroom'] as Map?)?['name'] as String?) ?? 'Subject',
        dueDate: dueDate,
        isSubmitted: isSubmitted,
        status: isSubmitted ? 'SUBMITTED' : (isOverdue ? 'OVERDUE' : 'PENDING'),
        score: (submission?['score'] as num?)?.toDouble(),
        total: (submission?['total'] as num?)?.toInt(),
        percentage: (submission?['percentage'] as num?)?.toDouble(),
        submittedAt: DateTime.tryParse((submission?['submitted_at'] as String?) ?? ''),
      );
    }).toList(growable: false);

    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items;
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
