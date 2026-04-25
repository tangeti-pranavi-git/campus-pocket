import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../src/types/portal_user.dart';
import '../models/student_portal_models.dart';
import '../repositories/student_portal_repository.dart';

enum StudentPortalLoadState { idle, loading, success, error, refreshing }

class StudentPortalController extends ChangeNotifier {
  StudentPortalController(this._repository);

  final StudentPortalRepository _repository;

  StudentPortalLoadState _state = StudentPortalLoadState.idle;
  StudentDashboardData? _dashboard;
  String? _errorMessage;
  bool _realtimeHealthy = true;
  int? _activeStudentId;
  bool _isLoadingNow = false;

  StreamSubscription<List<Map<String, dynamic>>>? _attendanceSub;
  StreamSubscription<List<Map<String, dynamic>>>? _submissionSub;

  StudentPortalLoadState get state => _state;
  StudentDashboardData? get dashboard => _dashboard;
  String? get errorMessage => _errorMessage;
  bool get realtimeHealthy => _realtimeHealthy;

  Future<void> ensureInitialized(PortalUser? user) async {
    if (user == null || user.role != UserRole.student) return;
    if (_activeStudentId == user.id && _dashboard != null) return;
    await loadDashboard(user: user);
  }

  Future<void> loadDashboard({required PortalUser? user, bool forceRefresh = false}) async {
    if (_isLoadingNow) return;

    if (user == null || user.role != UserRole.student) {
      _state = StudentPortalLoadState.error;
      _errorMessage = 'Unauthorized user role.';
      notifyListeners();
      return;
    }

    _isLoadingNow = true;
    _state = forceRefresh && _dashboard != null
        ? StudentPortalLoadState.refreshing
        : StudentPortalLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (forceRefresh) {
        _repository.clearCache();
      }

      final data = await _repository.getDashboard(
        studentId: user.id,
        studentName: user.fullName,
        forceRefresh: forceRefresh,
      );

      _dashboard = data;
      _activeStudentId = user.id;
      _state = StudentPortalLoadState.success;
      _subscribeRealtime(user);
    } catch (_) {
      _state = StudentPortalLoadState.error;
      _errorMessage = 'Failed to load student dashboard. Pull to refresh.';
    } finally {
      _isLoadingNow = false;
    }

    notifyListeners();
  }

  Future<void> refresh({required PortalUser? user}) async {
    await loadDashboard(user: user, forceRefresh: true);
  }

  Future<ClassDetailData> loadClassDetail({
    required PortalUser user,
    required int classroomId,
    bool forceRefresh = false,
  }) {
    return _repository.getClassDetail(
      studentId: user.id,
      studentName: user.fullName,
      classroomId: classroomId,
      forceRefresh: forceRefresh,
    );
  }

  Future<PerformanceReportData> loadPerformanceReport({
    required PortalUser user,
    required int classroomId,
    bool forceRefresh = false,
  }) {
    return _repository.getPerformanceReport(
      studentId: user.id,
      studentName: user.fullName,
      classroomId: classroomId,
      forceRefresh: forceRefresh,
    );
  }

  Future<StudentInsight> loadInsight({
    required PortalUser user,
    int? classroomId,
    bool forceRefresh = false,
  }) {
    return _repository.getInsight(
      studentId: user.id,
      studentName: user.fullName,
      classroomId: classroomId,
      forceRefresh: forceRefresh,
    );
  }

  void _subscribeRealtime(PortalUser user) {
    _attendanceSub?.cancel();
    _submissionSub?.cancel();

    final client = Supabase.instance.client;

    _attendanceSub = client
        .from('attendance')
        .stream(primaryKey: <String>['id'])
        .eq('student_id', user.id)
        .listen(
      (_) {
        _realtimeHealthy = true;
        loadDashboard(user: user, forceRefresh: true);
      },
      onError: (_) {
        _realtimeHealthy = false;
        notifyListeners();
      },
    );

    _submissionSub = client
        .from('assignment_submission')
        .stream(primaryKey: <String>['id'])
        .eq('user_id', user.id)
        .listen(
      (_) {
        _realtimeHealthy = true;
        loadDashboard(user: user, forceRefresh: true);
      },
      onError: (_) {
        _realtimeHealthy = false;
        notifyListeners();
      },
    );
  }

  Future<List<StudentTimetableItem>> loadTimetable({required PortalUser user}) {
    return _repository.getTimetable(schoolId: user.schoolId);
  }

  Future<List<StudentAnnouncementItem>> loadAnnouncements({required PortalUser user}) {
    return _repository.getAnnouncements(schoolId: user.schoolId);
  }

  Future<List<StudentHolidayItem>> loadHolidays({required PortalUser user}) {
    return _repository.getHolidays(schoolId: user.schoolId);
  }

  Future<List<StudentBadgeItem>> loadBadges({required PortalUser user}) {
    return _repository.getBadges(studentId: user.id);
  }

  Future<List<StudentAssignmentItem>> loadAssignments({required PortalUser user}) {
    return _repository.getAssignments(studentId: user.id);
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _submissionSub?.cancel();
    super.dispose();
  }
}
