import 'dart:io';

void replaceInFile(String path, RegExp from, String to) {
  final file = File(path);
  if (!file.existsSync()) return;
  file.writeAsStringSync(file.readAsStringSync().replaceAll(from, to));
}

void appendImport(String path, String importLine) {
  final file = File(path);
  if (!file.existsSync()) return;
  final content = file.readAsStringSync();
  if (!content.contains(importLine)) {
    file.writeAsStringSync("import '$importLine';\n$content");
  }
}

void main() {
  replaceInFile('lib/view/student_dashboard_screen.dart', RegExp(r"context\.push\('/student/profile'\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Profile')))))");
  replaceInFile('lib/view/student_dashboard_screen.dart', RegExp(r"context\.push\('/student/analytics'\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAnalyticsScreen()))");
  appendImport('lib/view/student_dashboard_screen.dart', 'student_analytics_screen.dart');
  appendImport('lib/view/student_dashboard_screen.dart', 'student_notifications_screen.dart');
  
  // Replace generic context.push('/student/quizzes/${ID}')
  replaceInFile('lib/view/student_dashboard_screen.dart', RegExp(r"context\.push\('/student/quizzes/\$\{([^}]+)\}'\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQuizDetailScreen(quizId: \$1)))");
  appendImport('lib/view/student_dashboard_screen.dart', 'student_quiz_detail_screen.dart');

  replaceInFile('lib/view/student_notifications_screen.dart', RegExp(r"context\.push\('/student/quizzes/\$\{([^}]+)\}'\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQuizDetailScreen(quizId: \$1)))");
  appendImport('lib/view/student_notifications_screen.dart', 'student_quiz_detail_screen.dart');

  replaceInFile('lib/view/student_quiz_detail_screen.dart', RegExp(r"context\.push\('/student/quiz/take',\s*extra:\s*([^)]+)\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQuizTakingScreen(quiz: \$1)))");
  appendImport('lib/view/student_quiz_detail_screen.dart', 'student_quiz_taking_screen.dart');
  replaceInFile('lib/view/student_quiz_detail_screen.dart', RegExp(r"context\.push\(\s*'/student/quiz/result',\s*extra:\s*\{\s*'quiz':\s*([^,]+),\s*'attempt':\s*([^}]+)\s*\}\s*\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQuizResultScreen(quiz: \$1, attempt: \$2)))");
  appendImport('lib/view/student_quiz_detail_screen.dart', 'student_quiz_result_screen.dart');

  replaceInFile('lib/view/student_quiz_list_screen.dart', RegExp(r"context\.push\('/student/quiz/take',\s*extra:\s*([^)]+)\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQuizTakingScreen(quiz: \$1)))");
  appendImport('lib/view/student_quiz_list_screen.dart', 'student_quiz_taking_screen.dart');
  replaceInFile('lib/view/student_quiz_list_screen.dart', RegExp(r"context\.push\(\s*'/student/quiz/result',\s*extra:\s*\{\s*'quiz':\s*([^,]+),\s*'attempt':\s*([^}]+)\s*\}\s*\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQuizResultScreen(quiz: \$1, attempt: \$2)))");
  appendImport('lib/view/student_quiz_list_screen.dart', 'student_quiz_result_screen.dart');

  replaceInFile('lib/view/student_my_results_screen.dart', RegExp(r"context\.push\(\s*'/student/quiz/result',\s*extra:\s*\{\s*'quiz':\s*([^,]+),\s*'attempt':\s*([^}]+)\s*\}\s*\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => StudentQuizResultScreen(quiz: \$1, attempt: \$2)))");
  appendImport('lib/view/student_my_results_screen.dart', 'student_quiz_result_screen.dart');

  replaceInFile('lib/view/quiz_list_screen.dart', RegExp(r"context\.push\('/quiz/detail',\s*extra:\s*([^)]+)\)"), "Navigator.push(context, MaterialPageRoute(builder: (_) => QuizDetailScreen(quiz: \$1)))");
  appendImport('lib/view/quiz_list_screen.dart', 'quiz_detail_screen.dart');

  replaceInFile('lib/view/student_quiz_taking_screen.dart', RegExp(r"context\.pushReplacement\(\s*'/student/quiz/result',\s*extra:\s*\{\s*'quiz':\s*([^,]+),\s*'attempt':\s*([^}]+)\s*\}\s*\)"), "Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StudentQuizResultScreen(quiz: \$1, attempt: \$2)))");
}
