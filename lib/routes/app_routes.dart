class AppRoutes {
  static const String splash = '/splash';
  static const String loading = '/loading';
  static const String login = '/login';
  static const String unauthorized = '/unauthorized';
  static const String studentHome = '/student/home';
  static const String studentFeed = '/student/feed';
  static const String studentInsights = '/student/insights';
  static String studentClassDetail(int classroomId) => '/student/class/$classroomId';
  static String studentPerformance(int classroomId) => '/student/performance/$classroomId';
  static const String parentHome = '/parent/home';
  static const String parentAttendance = '/parent/attendance';
  static const String parentTimetable = '/parent/timetable';
  static const String parentReportCard = '/parent/report-card';
  static const String parentAnnouncements = '/parent/announcements';
  static const String parentAssignments = '/parent/assignments';
  static const String parentHolidays = '/parent/holidays';
  static const String parentFees = '/parent/fees';
  static const String parentMessages = '/parent/messages';
  static const String parentVoiceAssistant = '/parent/voice-assistant';
  static const String parentInterventionCoach = '/parent/intervention-coach';
  static const String parentBlindSpotDetector = '/parent/blind-spot-detector';
  static const String profile = '/profile';
  static const String aiChat = '/ai-chat';

  static const String studentAttendance = '/student/attendance';
  static const String studentTimetable = '/student/timetable';
  static const String studentReportCard = '/student/report-card';
  static const String studentAnnouncements = '/student/announcements';
  static const String studentAssignments = '/student/assignments';
  static const String studentHolidays = '/student/holidays';
  static const String studentBadges = '/student/badges';
  static const String studentRiskPrediction = '/student/risk-prediction';
  static const String studentBurnout = '/student/burnout';
  static const String studentExamReadiness = '/student/exam-readiness';

  static String childDetail(int childId) => '/parent/child/$childId';
  static String classroomDetail(int childId, int classroomId) =>
      '/parent/child/$childId/classroom/$classroomId';
}
