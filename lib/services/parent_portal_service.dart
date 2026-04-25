import 'package:supabase_flutter/supabase_flutter.dart';

import '../src/services/supabase_service.dart';

class ParentPortalService {
  ParentPortalService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<List<int>> fetchLinkedStudentIds(int parentId) async {
    final rows = await _client
        .from('parent_student_link')
        .select('student_id')
        .eq('parent_id', parentId);

    return (rows as List)
        .map((row) => (row['student_id'] as num).toInt())
        .toList(growable: false);
  }

  Future<Map<int, Map<String, dynamic>>> fetchStudents(List<int> studentIds) async {
    if (studentIds.isEmpty) return const {};

    final rows = await _client
        .from('user')
        .select('id,full_name,school_id,role')
        .inFilter('id', studentIds)
        .eq('role', 'student');

    final map = <int, Map<String, dynamic>>{};
    for (final row in (rows as List)) {
      final id = (row['id'] as num).toInt();
      map[id] = Map<String, dynamic>.from(row as Map);
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceForStudents(List<int> studentIds) async {
    if (studentIds.isEmpty) return const [];

    final rows = await _client
        .from('attendance')
        .select('student_id,status,session:session_id(id,classroom_id,session_date,topic)')
        .inFilter('student_id', studentIds);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchSubmissionsForStudents(List<int> studentIds) async {
    if (studentIds.isEmpty) return const [];

    final rows = await _client
        .from('assignment_submission')
        .select(
          'user_id,percentage,score,total,submitted_at,'
          'assignment:assignment_id(id,title,classroom_id,due_date,classroom:classroom_id(id,name))',
        )
        .inFilter('user_id', studentIds);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchFeesForStudents(List<int> studentIds) async {
    if (studentIds.isEmpty) return const [];

    final rows = await _client
        .from('fees')
        .select('id,student_id,amount,due_date,status,paid_on,created_at')
        .inFilter('student_id', studentIds)
        .order('due_date', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchClassroomMembershipsForStudents(List<int> studentIds) async {
    if (studentIds.isEmpty) return const [];

    final rows = await _client
        .from('classroom_membership')
        .select('user_id,classroom_id,classroom:classroom_id(id,name,school_id)')
        .inFilter('user_id', studentIds)
        .eq('role', 'student');

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<int>> fetchClassroomIdsForStudent(int studentId) async {
    final rows = await _client
        .from('classroom_membership')
        .select('classroom_id')
        .eq('user_id', studentId)
        .eq('role', 'student');

    return (rows as List)
        .map((row) => (row['classroom_id'] as num).toInt())
        .toSet()
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchAssignmentsForClassrooms(List<int> classroomIds) async {
    if (classroomIds.isEmpty) return const [];
    final rows = await _client
        .from('assignment')
        .select('id,title,due_date,classroom_id,classroom:classroom_id(id,name)')
        .inFilter('classroom_id', classroomIds)
        .order('due_date', ascending: true);

    return (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchSubmissionsForStudent(int studentId) async {
    final rows = await _client
        .from('assignment_submission')
        .select('assignment_id,score,total,percentage,submitted_at')
        .eq('user_id', studentId);

    return (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList(growable: false);
  }

  Future<int?> fetchSchoolIdForStudent(int studentId) async {
    final row = await _client
        .from('user')
        .select('school_id')
        .eq('id', studentId)
        .eq('role', 'student')
        .maybeSingle();
    if (row == null) return null;
    return (row['school_id'] as num?)?.toInt();
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements(int schoolId) async {
    final rows = await _client
        .from('announcements')
        .select()
        .eq('school_id', schoolId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchHolidays(int schoolId) async {
    final rows = await _client
        .from('holidays')
        .select()
        .eq('school_id', schoolId)
        .order('date', ascending: true);

    return (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchMessages(int parentId, int studentId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('parent_id', parentId)
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchTimetable(List<int> classroomIds) async {
    if (classroomIds.isEmpty) return const [];
    
    final rows = await _client
        .from('class_timetable')
        .select('*, classroom:classroom_id(id,name)')
        .inFilter('classroom_id', classroomIds)
        .order('start_time', ascending: true);

    return (rows as List).map((row) => Map<String, dynamic>.from(row as Map)).toList(growable: false);
  }

  Future<void> sendMessage({
    required int schoolId,
    required int parentId,
    required int studentId,
    required String teacherName,
    required String subject,
    required String message,
  }) async {
    try {
      await _client.from('messages').insert({
        'school_id': schoolId,
        'parent_id': parentId,
        'student_id': studentId,
        'teacher_name': teacherName,
        'subject': subject,
        'message': message,
        'status': 'UNREAD',
      });
    } catch (_) {
      // Ignore failure if SQL migration 004/005 hasn't been run
    }
  }
}
