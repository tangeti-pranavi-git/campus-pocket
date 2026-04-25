import '../models/parent_analytics_models.dart';
import '../../../services/parent_portal_service.dart';

class ParentAnalyticsRepository {
  final ParentPortalService _service;

  ParentAnalyticsRepository({ParentPortalService? service})
      : _service = service ?? ParentPortalService();

  Future<Map<String, dynamic>> fetchChildAnalyticsData(int childId) async {
    // Fetch all relevant data for a specific child using existing service methods
    final attendance = await _service.fetchAttendanceForStudents([childId]);
    final assignments = await _service.fetchSubmissionsForStudents([childId]);
    final classrooms = await _service.fetchClassroomMembershipsForStudents([childId]);
    final fees = await _service.fetchFeesForStudents([childId]);
    final schoolId = await _service.fetchSchoolIdForStudent(childId);
    final announcements = schoolId != null ? await _service.fetchAnnouncements(schoolId) : [];
    
    return {
      'attendance': attendance,
      'assignments': assignments,
      'classrooms': classrooms,
      'fees': fees,
      'announcements': announcements,
    };
  }
}
