import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../src/services/supabase_service.dart';

class StudentPortalService {
  StudentPortalService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchStudentMemberships(int studentId) async {
    final rows = await _client
        .from('classroom_membership')
        .select('classroom_id,classroom:classroom_id(id,name,school_id),role')
        .eq('user_id', studentId)
        .eq('role', 'student');

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchAttendance(int studentId) async {
    final rows = await _client
        .from('attendance')
        .select('id,student_id,status,session:session_id(id,classroom_id,session_date,topic)')
        .eq('student_id', studentId);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchSubmissions(int studentId) async {
    final rows = await _client
        .from('assignment_submission')
        .select(
          'id,user_id,percentage,score,total,submitted_at,'
          'assignment:assignment_id(id,title,classroom_id,due_date,classroom:classroom_id(id,name))',
        )
        .eq('user_id', studentId)
        .order('submitted_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchClassSessions(List<int> classIds) async {
    if (classIds.isEmpty) return const [];

    final rows = await _client
        .from('class_session')
        .select('id,classroom_id,session_date,topic')
        .inFilter('classroom_id', classIds)
        .order('session_date', ascending: true);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
  Future<List<Map<String, dynamic>>> fetchTimetable(int schoolId) async {
    final rows = await _client
        .from('class_timetable')
        .select('id,classroom_id,teacher_name,subject,room_name,start_time,end_time,day_of_week')
        .eq('school_id', schoolId)
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements(int schoolId) async {
    final rows = await _client
        .from('announcements')
        .select('*')
        .eq('school_id', schoolId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchHolidays(int schoolId) async {
    final rows = await _client
        .from('holidays')
        .select('*')
        .eq('school_id', schoolId)
        .order('date', ascending: true);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> fetchBadges(int studentId) async {
    final rows = await _client
        .from('student_badges')
        .select('*')
        .eq('student_id', studentId)
        .order('earned_at', ascending: false);

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }
}
