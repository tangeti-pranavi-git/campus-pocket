enum UserRole { student, parent }

UserRole? parseUserRole(String raw) {
  switch (raw) {
    case 'student':
      return UserRole.student;
    case 'parent':
      return UserRole.parent;
    default:
      return null;
  }
}

class PortalUser {
  const PortalUser({
    required this.id,
    required this.username,
    required this.role,
    required this.fullName,
    required this.schoolId,
  });

  final int id;
  final String username;
  final UserRole role;
  final String fullName;
  final int schoolId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role.name,
      'fullName': fullName,
      'schoolId': schoolId,
    };
  }

  factory PortalUser.fromJson(Map<String, dynamic> json) {
    final parsedRole = parseUserRole((json['role'] as String?) ?? '');
    if (parsedRole == null) {
      throw const FormatException('Invalid user role');
    }

    return PortalUser(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      role: parsedRole,
      fullName: json['fullName'] as String,
      schoolId: (json['schoolId'] as num).toInt(),
    );
  }
}
