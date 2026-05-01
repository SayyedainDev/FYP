// ============================================================
//  PalPath – Master Integration Test Runner
//  Runs ALL student + doctor E2E tests in one command:
//
//    flutter test integration_test/all_tests_runner.dart \
//      -d <device-id> --reporter expanded
// ============================================================

import 'package:integration_test/integration_test.dart';

import 'student_e2e_test.dart' as student_tests;
import 'doctor_e2e_test.dart' as doctor_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Run student tests first
  student_tests.main();

  // Then doctor tests
  doctor_tests.main();
}
