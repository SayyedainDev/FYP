// Non-web fallback: keep the session role in memory so the app behaves
// like a single-session environment instead of always reporting "no role"
// (which forces an immediate logout in AuthProvider.userRole).
String? _sessionRole;

void saveUserRole(String role) {
  _sessionRole = role;
}

String? getUserRole() {
  return _sessionRole;
}

void clearSession() {
  _sessionRole = null;
}
