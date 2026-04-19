# Student Registration Tests - Optional Fields

This directory contains comprehensive unit tests for the Dental Care app's authentication system, focusing on student registration with optional fields.

## Test File: `auth_provider_registration_test.dart`

This test file validates that students can register successfully with or without optional fields (university, yearOfStudy, batchCode).

### Test Coverage

#### 1. **Student Registration - With Optional Fields**
- ✅ Register with all fields provided
- ✅ Register WITHOUT optional fields (yearOfStudy, batchCode, university)
- ✅ Register WITH PARTIAL optional fields

#### 2. **Dentist Registration - Optional Fields Empty**
- ✅ Dentist registration with default empty optional fields

#### 3. **Registration Validation - Required Fields**
- ✅ Throws error when userId is missing
- ✅ Throws error when firstName is missing
- ✅ Throws error when lastName is missing
- ✅ Throws error when CNIC is missing
- ✅ Throws error when address is missing
- ✅ Throws error when highestEducation is missing
- ✅ Throws error when email is missing

#### 4. **Email Format Validation**
- ✅ Throws error for invalid email format
- ✅ Accepts valid email formats

#### 5. **Password Requirements**
- ✅ Throws error when password is less than 8 characters
- ✅ Accepts password with exactly 8 characters

#### 6. **Loading State Management**
- ✅ Sets loading to true during registration
- ✅ Resets loading state even if registration fails

#### 7. **Whitespace Handling**
- ✅ Trims whitespace from all input fields

## Running the Tests

### Via Terminal

```bash
# Run specific test file
flutter test test/auth_provider_registration_test.dart

# Run tests with verbose output
flutter test test/auth_provider_registration_test.dart -v

# Run tests with coverage
flutter test test/auth_provider_registration_test.dart --coverage
```

### Via VS Code

1. Open the test file: `test/auth_provider_registration_test.dart`
2. Click the "Run" or "Debug" button above any test function
3. Or press `Ctrl+F5` to run all tests in the file

## Test Scenarios

### Scenario 1: Student with Complete Information
A student registering with all fields including university, year of study, and batch code.

```dart
final form = {
  'email': 'student@dental.com',
  'firstName': 'John',
  'lastName': 'Doe',
  'userId': 'STU001',
  'cnic': '12345-6789012-3',
  'address': '123 Main St, City',
  'highestEducation': 'Undergraduate',
  'university': 'Dental University',
  'yearOfStudy': '3rd Year',
  'batchCode': 'BATCH2023',
};
```

**Result**: ✅ Registration succeeds

### Scenario 2: Student with Minimal Information
A student registering with only required fields (no university, year of study, or batch code).

```dart
final form = {
  'email': 'student@dental.com',
  'firstName': 'Jane',
  'lastName': 'Smith',
  'userId': 'STU002',
  'cnic': '98765-4321098-7',
  'address': '456 Oak Ave, City',
  'highestEducation': 'Postgraduate',
};
```

**Expected Behavior**: 
- Optional fields default to empty strings
- Registration succeeds without university, yearOfStudy, perbatchCode
- ✅ Test passes

### Scenario 3: Dentist Registration
A dentist registering (no student-specific fields needed).

```dart
final form = {
  'email': 'dentist@clinic.com',
  'firstName': 'Dr.',
  'lastName': 'Williams',
  'userId': 'DENT001',
  'cnic': '55555-6666666-7',
  'address': 'Clinical Suite 100',
  'highestEducation': 'Doctorate',
  'role': 'Dentist',
};
```

**Expected Behavior**:
- All optional fields default to empty
- dentist role is properly set
- ✅ Test passes

## Key Features Being Tested

### 1. Optional Field Handling
The tests verify that `university`, `yearOfStudy`, and `batchCode` are truly optional:
- These fields have default empty string values in the `UserModel`
- They can be omitted from the registration form
- They are passed as empty strings to Firebase if not provided

### 2. Required Field Validation
All of these fields are **required**:
- `email` - Must be a valid email format
- `firstName` - Cannot be empty
- `lastName` - Cannot be empty
- `userId` - Professional/Student ID
- `cnic` - License or CNIC number
- `address` - Practice or residential address
- `highestEducation` - Educational qualification

### 3. Input Sanitization
- Whitespace is automatically trimmed from all fields
- Empty fields can be detected and validated

### 4. Error Handling
- Validation errors are thrown before making Firebase calls
- Proper error messages guide users on what's needed
- Loading state is reset even if registration fails

## Implementation Details

### Mock Strategy
The tests use `mocktail` to mock:
- `FirebaseService` - Database/auth operations
- `AuthController` - Business logic

This allows testing the provider layer in isolation without actual Firebase calls.

### Registration Flow
1. Provider receives form data and password
2. Input validation occurs (required fields, email format, password length)
3. Whitespace is trimmed from all fields
4. Optional fields default to empty strings if not provided
5. Controller is called with all data
6. Success/error is returned to caller

## Expected Test Output

When running the tests, you should see output similar to:

```
AuthProvider - Student Registration with Optional Fields
  Student Registration - With Optional Fields
    ✓ Should successfully register student with all fields provided
    ✓ Should successfully register student WITHOUT optional fields (university, yearOfStudy, batchCode)
    ✓ Should successfully register student with PARTIAL optional fields
  Dentist Registration - Optional Fields Empty
    ✓ Should successfully register dentist with empty optional fields
  Registration Validation - Required Fields
    ✓ Should throw error when userId is missing
    ✓ Should throw error when firstName is missing
    ✓ Should throw error when lastName is missing
    ✓ Should throw error when CNIC is missing
    ✓ Should throw error when address is missing
    ✓ Should throw error when highestEducation is missing
    ✓ Should throw error when email is missing
  ...
  
All tests passed!
```

## Troubleshooting

### Issue: Tests fail with "Cannot find AuthProvider constructor"
**Solution**: Ensure `AuthProvider` is constructed with a `FirebaseService`, not an `AuthController`.

### Issue: Tests fail with "loading property not found"
**Solution**: Verify that `AuthProvider` has a `loading` getter that returns the `_loading` boolean.

### Issue: Tests fail with "userRole property not found"
**Solution**: Verify that `AuthProvider` has a `userRole` getter that returns the `_role` string.

## Adding More Tests

To add new test cases:

1. Create a new `test()` function inside one of the `group()` blocks
2. Follow the Arrange-Act-Assert (AAA) pattern:
   ```dart
   test('Test description', () async {
     // Arrange: Setup test data
     final form = {...};
     
     // Act: Call the function being tested
     await authProvider.register(form, password);
     
     // Assert: Verify the results
     expect(authProvider.uid, expectedUid);
   });
   ```
3. Use `when()` and `verify()` for mocking
4. Run tests to ensure they pass

## Related Files

- `lib/provider/auth_provider.dart` - The class being tested
- `lib/controller/auth_controller.dart` - Business logic controller
- `lib/service/firebase_service.dart` - Firebase operations
- `lib/models/user_model.dart` - User data model
- `pubspec.yaml` - Project dependencies (flutter_test, mocktail)

## Dependencies

- `flutter_test` - Flutter testing framework
- `mocktail` - Mocking library for Dart/Flutter

Ensure these are installed in your `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
```
