class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role; // 'dentist', 'student', 'admin', etc.

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = 'dentist',
  });

  // Get initials from display name
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // Get title (Dr. for dentists/doctors)
  String get title {
    if (role.toLowerCase() == 'dentist' || role.toLowerCase() == 'doctor') {
      return 'Dr.';
    }
    return '';
  }

  // Get full display name with title
  String get fullDisplayName {
    return title.isEmpty ? displayName : '$title $displayName';
  }

  // Check if user is dentist (can create/edit cases)
  bool get isDentist =>
      role.toLowerCase() == 'dentist' || role.toLowerCase() == 'doctor';

  // Check if user is student (view-only access)
  bool get isStudent => role.toLowerCase() == 'student';

  // Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';
}
