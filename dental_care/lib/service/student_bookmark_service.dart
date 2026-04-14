import 'package:shared_preferences/shared_preferences.dart';

class StudentBookmarkService {
  static const String _key = 'student_bookmarked_quiz_ids';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? <String>[]).toSet();
  }

  static Future<void> save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.toList()..sort());
  }

  static Future<Set<String>> toggle(String quizId) async {
    final current = await load();
    if (current.contains(quizId)) {
      current.remove(quizId);
    } else {
      current.add(quizId);
    }
    await save(current);
    return current;
  }
}
