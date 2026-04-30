import 'dart:html' as html;

void saveUserRole(String role) {
  html.window.sessionStorage['userRole'] = role;
}

String? getUserRole() {
  return html.window.sessionStorage['userRole'];
}

void clearSession() {
  html.window.sessionStorage.clear();
}
