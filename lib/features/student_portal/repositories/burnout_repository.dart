import '../models/student_analytics_models.dart';
import '../services/student_portal_service.dart';

class BurnoutRepository {
  final StudentPortalService _service;

  BurnoutRepository({StudentPortalService? service})
      : _service = service ?? StudentPortalService();

  Future<Map<String, dynamic>> fetchRawAnalyticsData(int studentId) async {
    final memberships = await _service.fetchStudentMemberships(studentId);
    final classIds = memberships
        .map((m) => (m['classroom_id'] as num?)?.toInt())
        .whereType<int>()
        .toList();

    if (classIds.isEmpty) return {};

    final attendanceRows = await _service.fetchAttendance(studentId);
    final submissionRows = await _service.fetchSubmissions(studentId);
    
    // For deadlines, we can fetch assignments
    final List<Map<String, dynamic>> assignments = [];
    try {
      // In a real app, we'd have a fetchUpcomingAssignments method
      // For now, we'll use the submissions and memberships to infer
    } catch (_) {}

    return {
      'memberships': memberships,
      'attendance': attendanceRows,
      'submissions': submissionRows,
    };
  }
}
