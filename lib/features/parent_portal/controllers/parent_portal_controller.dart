import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../repositories/parent_portal_repository.dart';
import '../../../src/types/portal_user.dart';
import '../models/parent_portal_models.dart';

enum ParentPortalLoadState { idle, loading, success, error, refreshing }

class ParentPortalController extends ChangeNotifier {
  ParentPortalController(this._repository);

  final ParentPortalRepository _repository;

  ParentPortalLoadState _state = ParentPortalLoadState.idle;
  DashboardOverview? _dashboard;
  String? _errorMessage;
  int? _selectedChildId;
  StreamSubscription<List<Map<String, dynamic>>>? _attendanceSub;
  StreamSubscription<List<Map<String, dynamic>>>? _submissionSub;
  StreamSubscription<List<Map<String, dynamic>>>? _feeSub;
  StreamSubscription<List<Map<String, dynamic>>>? _announcementSub;
  StreamSubscription<List<Map<String, dynamic>>>? _messageSub;

  ParentPortalLoadState get state => _state;
  DashboardOverview? get dashboard => _dashboard;
  String? get errorMessage => _errorMessage;
  int? get selectedChildId => _selectedChildId;

  bool get isLoading => _state == ParentPortalLoadState.loading;
  bool get isRefreshing => _state == ParentPortalLoadState.refreshing;
  bool get hasError => _state == ParentPortalLoadState.error;

  Future<void> loadDashboard({required PortalUser? user, bool forceRefresh = false}) async {
    if (user == null || user.role != UserRole.parent) {
      _state = ParentPortalLoadState.error;
      _errorMessage = 'Unauthorized user role.';
      notifyListeners();
      return;
    }

    _state = forceRefresh && _dashboard != null
        ? ParentPortalLoadState.refreshing
        : ParentPortalLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (forceRefresh) {
        _repository.clearAllCache();
      }

      final data = await _repository.getParentDashboard(
        parentId: user.id,
        parentName: user.fullName,
        forceRefresh: forceRefresh,
      );

      _dashboard = data;
      _state = ParentPortalLoadState.success;
      
      if (_selectedChildId == null && data.children.isNotEmpty) {
        _selectedChildId = data.children.first.childId;
      }
      
      _subscribeRealtime(
        childIds: data.children.map((e) => e.childId).toList(growable: false),
        schoolIds: data.children.map((e) => e.schoolId).toSet().toList(growable: false),
        user: user,
      );
    } catch (_) {
      _state = ParentPortalLoadState.error;
      _errorMessage = 'Failed to load parent dashboard. Pull to refresh.';
    }

    notifyListeners();
  }
  
  void selectChild(int childId) {
    if (_selectedChildId == childId) return;
    _selectedChildId = childId;
    notifyListeners();
  }

  Future<void> refresh({required PortalUser? user}) {
    return loadDashboard(user: user, forceRefresh: true);
  }

  Future<ChildDetailData> loadChildDetail({
    required PortalUser user,
    required int childId,
    bool forceRefresh = false,
  }) {
    return _repository.getChildDetail(
      parentId: user.id,
      parentName: user.fullName,
      childId: childId,
      forceRefresh: forceRefresh,
    );
  }

  Future<ClassroomDetailData> loadClassroomDetail({
    required PortalUser user,
    required int childId,
    required int classroomId,
    bool forceRefresh = false,
  }) {
    return _repository.getClassroomDetail(
      parentId: user.id,
      parentName: user.fullName,
      childId: childId,
      classroomId: classroomId,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<AnnouncementItem>> loadAnnouncements(int schoolId) {
    return _repository.getAnnouncements(schoolId: schoolId);
  }

  Future<List<HolidayItem>> loadHolidays(int schoolId) {
    return _repository.getHolidays(schoolId: schoolId);
  }

  Future<List<MessageItem>> loadMessages(int parentId, int childId) {
    return _repository.getMessages(parentId: parentId, childId: childId);
  }

  Future<void> sendMessage({
    required int schoolId,
    required int parentId,
    required int studentId,
    required String teacherName,
    required String subject,
    required String message,
  }) async {
    await _repository.sendMessage(
      schoolId: schoolId,
      parentId: parentId,
      studentId: studentId,
      teacherName: teacherName,
      subject: subject,
      message: message,
    );
  }

  Future<List<TimetableSessionItem>> loadTimetable(int childId) {
    return _repository.getTimetable(childId: childId);
  }

  Future<List<Map<String, String>>> getTeachers(int childId) async {
    final timetable = await _repository.getTimetable(childId: childId);
    final Set<String> uniquePairs = {};
    final List<Map<String, String>> result = [];
    
    for (final session in timetable) {
      final key = '${session.teacherName}_${session.subject}';
      if (!uniquePairs.contains(key)) {
        uniquePairs.add(key);
        result.add({
          'teacherName': session.teacherName,
          'subject': session.subject,
        });
      }
    }
    
    result.sort((a, b) => a['teacherName']!.compareTo(b['teacherName']!));
    return result;
  }

  void _subscribeRealtime({
    required List<int> childIds,
    required List<int> schoolIds,
    required PortalUser user,
  }) {
    _attendanceSub?.cancel();
    _submissionSub?.cancel();
    _feeSub?.cancel();
    _announcementSub?.cancel();
    _messageSub?.cancel();

    if (childIds.isEmpty) return;

    final client = Supabase.instance.client;

    _attendanceSub = client
        .from('attendance')
        .stream(primaryKey: <String>['id'])
        .inFilter('student_id', childIds)
        .listen((_) {
      loadDashboard(user: user, forceRefresh: true);
    });

    _submissionSub = client
        .from('assignment_submission')
        .stream(primaryKey: <String>['id'])
        .inFilter('user_id', childIds)
        .listen((_) {
      loadDashboard(user: user, forceRefresh: true);
    });

    _feeSub = client
        .from('fees')
        .stream(primaryKey: <String>['id'])
        .inFilter('student_id', childIds)
        .listen((_) {
      loadDashboard(user: user, forceRefresh: true);
    });

    if (schoolIds.isNotEmpty) {
      _announcementSub = client
          .from('announcements')
          .stream(primaryKey: <String>['id'])
          .inFilter('school_id', schoolIds)
          .listen((_) {
        loadDashboard(user: user, forceRefresh: true);
      });
    }

    _messageSub = client
        .from('messages')
        .stream(primaryKey: <String>['id'])
        .eq('parent_id', user.id)
        .listen((_) {
      loadDashboard(user: user, forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _submissionSub?.cancel();
    _feeSub?.cancel();
    _announcementSub?.cancel();
    _messageSub?.cancel();
    super.dispose();
  }
}
