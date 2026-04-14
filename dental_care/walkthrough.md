# Walkthrough: Error Handling + Dialog Improvements

## What was fixed immediately
- Resolved parser failure in `lib/view/lecture_notes_screen.dart` delete-note flow (broken `SnackBar` construction).
- Confirmed `lib/view/main_layout.dart` has no analyzer errors.

## Global setup status
- `main.dart` already uses:
  - `runZonedGuarded`
  - `FlutterError.onError`
  - `PlatformDispatcher.instance.onError`
  - `navigatorKey` via `GlobalErrorHandler`

## Enhancements completed in this pass

### 1) Dialog system hardening (`lib/utils/app_dialogs.dart`)
- Added blocking dialog queue so only one blocking dialog is visible at a time.
- Added semantic labels for each dialog and action button.
- Added autofocus on dialog title/message node for screen reader announcement.
- Added retry debounce guard for retry actions.
- Kept all required dialog entrypoints in place.

### 2) Global error classification (`lib/utils/global_error_handler.dart`)
- Added classification flow: network, timeout, auth, permission, validation, unknown.
- Mapped classification to specific dialog APIs.
- Added session-expired path to redirect user to login route.
- Preserved internal logging while keeping user-facing messages friendly.

### 3) Quiz provider hardening (`lib/providers/quiz_provider.dart`, `lib/providers/quiz_attempt_provider.dart`)
- Added a consistent 30-second timeout wrapper for async Firestore, HTTP, and backend calls.
- Replaced raw exception-to-UI strings with friendly mapped messages.
- Added HTTP status-based mapping for quiz monitoring endpoint responses.
- Kept provider APIs stable while improving error semantics for UI dialogs.

### 4) Non-quiz provider hardening
- Added shared utility: `lib/utils/provider_error_utils.dart`.
- Propagated timeout and mapped error messages across:
  - `lib/providers/patient_provider.dart`
  - `lib/providers/scan_provider.dart`
  - `lib/providers/case_provider.dart`
  - `lib/providers/lecture_notes_provider.dart`
  - `lib/providers/appointment_provider.dart`
  - `lib/providers/medical_history_provider.dart`
  - `lib/providers/audit_log_provider.dart`
  - `lib/providers/analytics_provider.dart`
  - `lib/providers/treatment_plan_provider.dart`

### 5) Service-layer hardening (current pass)
- Added timeout and friendly error handling to:
  - `lib/providers/lecture_notes_provider_supabase.dart`
  - `lib/service/rag_service.dart`
  - `lib/service/firebase_service.dart`
  - `lib/service/data_backup_service.dart`
  - `lib/service/dental_disease_detection_service.dart`
- Aligned dental detection request timeout with the 30-second global policy.

### 6) Screen-level message sanitization (current pass)
- Removed raw exception text from active user-facing dialogs/snackbars in:
  - `lib/view/lecture_notes_screen.dart`
  - `lib/view/history_screen.dart`
  - `lib/view/quiz_detail_screen.dart`
  - `lib/view/quiz_list_screen.dart`
  - `lib/view/ai_quiz_screen.dart`
  - `lib/view/dentist_profile_screen.dart`
  - `lib/view/create_case_screen.dart`
  - `lib/view/settings_screen.dart`
- Updated `lib/service/quiz_pdf_service.dart` and `lib/service/rag_service.dart` to avoid propagating raw payload/exception text.

### 7) Unit test expansion (current pass)
- Updated and stabilized:
  - `test/student_quiz_list_screen_test.dart`
  - `test/login_test.dart`
  - `test/register_test.dart`
- Added/validated scenarios: empty-form validation warning, timeout dialogs, no-internet dialogs, and session-expired dialog behavior for quiz list.
- Added deterministic dialog-queue reset hook (`AppDialogs.resetForTest`) for stable widget testing.

## What remains (high priority)
1. Propagate standardized timeout/error mapping to any remaining service APIs and confirm parity with all edge retries.
2. Standardize the remaining legacy/backup screens (if still in use) to the same friendly-message policy.
3. Add auto-dismiss behavior for no-internet dialog when connectivity is restored.
4. Add analytics event logging for shown dialogs (title + type only, no stack/PII).
5. Expand test coverage for quiz dashboard/auth/core screens with error-path assertions.

## Validation snapshot
- Analyzer check passed for:
  - `lib/utils/provider_error_utils.dart`
  - `lib/providers/quiz_provider.dart`
  - `lib/providers/quiz_attempt_provider.dart`
  - `lib/providers/patient_provider.dart`
  - `lib/providers/scan_provider.dart`
  - `lib/providers/case_provider.dart`
  - `lib/providers/lecture_notes_provider.dart`
  - `lib/providers/appointment_provider.dart`
  - `lib/providers/medical_history_provider.dart`
  - `lib/providers/audit_log_provider.dart`
  - `lib/providers/analytics_provider.dart`
  - `lib/providers/treatment_plan_provider.dart`
  - `lib/providers/lecture_notes_provider_supabase.dart`
  - `lib/service/rag_service.dart`
  - `lib/service/firebase_service.dart`
  - `lib/service/data_backup_service.dart`
  - `lib/service/dental_disease_detection_service.dart`
  - `lib/utils/app_dialogs.dart`
  - `lib/utils/global_error_handler.dart`
- Project-wide verification should be run after timeout/error refactor is propagated across remaining screens/providers.
- Targeted tests passed: 9/9 (`login_test.dart`, `register_test.dart`, `student_quiz_list_screen_test.dart`).
