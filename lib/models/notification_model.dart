class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String type;
  final String priority;
  final bool isRead;
  final DateTime createdAt;
  final String? redirectRoute;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    this.redirectRoute,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      priority: json['priority'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      redirectRoute: json['redirect_route'],
    );
  }
}

class NotificationPreferences {
  final bool examsEnabled;
  final bool feesEnabled;
  final bool assignmentsEnabled;
  final bool announcementsEnabled;

  NotificationPreferences({
    required this.examsEnabled,
    required this.feesEnabled,
    required this.assignmentsEnabled,
    required this.announcementsEnabled,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      examsEnabled: json['exams_enabled'] ?? true,
      feesEnabled: json['fees_enabled'] ?? true,
      assignmentsEnabled: json['assignments_enabled'] ?? true,
      announcementsEnabled: json['announcements_enabled'] ?? true,
    );
  }
}
