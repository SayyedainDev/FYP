# Error Handling & Dialog System Implementation Plan

## Scope
Implement and verify production-grade global error handling, user-facing dialog UX, and targeted tests for the Flutter web app.

## Current Architecture Analysis

### Entry and global wiring
- `lib/main.dart` already initializes `runZonedGuarded`, `FlutterError.onError`, and `PlatformDispatcher.instance.onError`.
- `MaterialApp` is already wired to `GlobalErrorHandler.instance.navigatorKey`.

### Error handling utilities
- `lib/utils/global_error_handler.dart` exists and is singleton-based.
- `lib/utils/app_dialogs.dart` exists with required dialog method names.

### Navigation and screen map (from Main Layout + Sidebar)
- Shared route host: `MainLayout` + `NavigationProvider`.
- Dentist/Professor paths: Overview, Disease Detection, Patients, Scan History, Create Quiz, My Quizzes, Lecture Notes, Settings, Profile.
- Student paths: Overview, Available Quizzes, My Results, Settings, Profile.
- Quiz dashboard flow currently spans `ai_quiz_screen.dart`, `quiz_list_screen.dart`, and `student_quiz_list_screen.dart`.

## Status Matrix (Checklist Mapping)

## 1) Planning
- [x] Analyze architecture (`main.dart`, existing error handling)
- [x] Investigate screens/navigation paths (including quiz screens)
- [x] Create `implementation_plan.md`
- [ ] Present and iterate after user feedback

## 2) Global Error Handling
- [x] `GlobalErrorHandler` singleton present
- [x] `runZonedGuarded` in `main.dart`
- [x] `FlutterError.onError` override
- [x] `PlatformDispatcher.instance.onError` override
- [~] Classification expanded (network/auth/validation/permission/unknown), still heuristic for auth/permission parsing
- [~] Logging exists via `debugPrint`; Crashlytics integration pending

## 3) Dialog System
- [x] `AppDialogs` class exists
- [x] Required methods implemented (`showErrorDialog`, `showWarningDialog`, `showInfoDialog`, `showSessionExpiredDialog`, `showNoInternetDialog`, `showLoadingDialog`, `showUnsavedChangesDialog`)
- [x] Added dialog queue in `AppDialogs` (one blocking dialog at a time)
- [x] Added semantics labels for dialogs/buttons and autofocus title/message nodes
- [x] Added retry tap debounce guard for retry actions
- [ ] Auto-dismiss no-internet dialog on connectivity restoration
- [ ] Analytics logging for dialog display events (without PII/stack traces)

## 4) Subsystem Refactoring
- [~] 30-second timeout + exception mapping added to quiz providers (`quiz_provider.dart`, `quiz_attempt_provider.dart`)
- [~] Added `.timeout(Duration(seconds: 30))` + friendly mapping to core non-quiz providers (`patient_provider.dart`, `scan_provider.dart`, `case_provider.dart`, `lecture_notes_provider.dart`, `appointment_provider.dart`, `medical_history_provider.dart`, `audit_log_provider.dart`, `analytics_provider.dart`, `treatment_plan_provider.dart`)
- [~] Added timeout hardening to `lecture_notes_provider_supabase.dart` and key services (`rag_service.dart`, `firebase_service.dart`, `data_backup_service.dart`, `dental_disease_detection_service.dart`)
- [~] Timeout policy propagated to core service paths; remaining service files should be audited for parity
- [x] Removed raw exception interpolation from active service error paths (friendly messaging retained)
- [ ] Complete form validation standards across all forms

## 5) Screen Refactoring (Per-screen)
- [~] Screen-level async handling expanded; raw exception text removed from active user-facing dialogs/snackbars
- [ ] Refactor quiz dashboard screens fully
- [ ] Refactor auth screens fully
- [ ] Refactor core dashboard screens fully
- [ ] Refactor remaining screens with standardized dialog routing

## 6) Unit Testing
- [~] Existing tests present under `test/` and `integration_test/`
- [~] Expanded quiz/auth widget tests (`student_quiz_list_screen_test.dart`, `login_test.dart`, `register_test.dart`) with happy path + timeout + no-internet + session/validation checks
- [~] Validation/session tests added for login/register/student quiz list flows
- [ ] Add loading state and permission tests

## 7) Verification & Documentation
- [ ] Trace all Section 5 warning strings to implementation and tests
- [ ] Verify UX requirements (contrast, semantics, queueing, focus announcement)
- [ ] Verify global handler catches missing route + async crash
- [x] Generate `walkthrough.md` (next artifact)

## Implementation Sequence (Next)
1. **Service hardening (continue)**: apply timeout + translation to remaining service-layer APIs.
2. **Quiz dashboard screens**: complete remaining scenario handling with AppDialogs.
3. **Auth screens**: session expiry, access denied, throttling/account-locked UX.
4. **Core dashboard screens**: verify UI-level routing for mapped provider errors.
5. **Tests phase 1**: quiz dashboard + auth critical tests.
6. **Tests phase 2**: remaining screens/providers and edge scenarios.
7. **Verification pass**: warning checklist and UX audit closure.

## Risks / Notes
- Full “every screen” parity is significant; execution should be phased to keep regression risk low.
- Some requirements need platform-specific hooks (web unload, connectivity monitoring) not yet wired.
- Existing code paths currently still pass raw exception strings in places; these must be normalized per-screen.
