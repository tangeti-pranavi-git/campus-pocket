import '../services/student_portal_service.dart';

class ExamReadinessRepository {
  final StudentPortalService _service;

  ExamReadinessRepository({StudentPortalService? service})
      : _service = service ?? StudentPortalService();

  Future<Map<String, dynamic>> fetchRawReadinessData(int studentId) async {
    final memberships = await _service.fetchStudentMemberships(studentId);
    final attendanceRows = await _service.fetchAttendance(studentId);
    final submissionRows = await _service.fetchSubmissions(studentId);

    return {
      'memberships': memberships,
      'attendance': attendanceRows,
      'submissions': submissionRows,
    };
  }
}
