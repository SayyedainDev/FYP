# Quick Reference: Student Registration Test Scenarios

## Overview
This guide provides quick reference for the most important test cases and how student registration works with optional fields.

## Registration Form Structure

### Required Fields (Must Always Provide)
```dart
{
  'email': 'user@domain.com',           // Valid email format
  'firstName': 'John',                   // At least 1 character
  'lastName': 'Doe',                     // At least 1 character
  'userId': 'STU001',                    // Unique identifier
  'cnic': '12345-6789012-3',            // License or CNIC
  'address': '123 Main St',             // Study/Work address
  'highestEducation': 'Undergraduate',   // Education level
}
```

### Optional Fields (Can Omit or Leave Empty)
```dart
{
  'university': 'Dental University',     // Student's university (optional)
  'yearOfStudy': '3rd Year',            // Student's year of study (optional)
  'batchCode': 'BATCH2023',             // Student's batch code (optional)
}
```

### Password Requirements
- Minimum 8 characters
- No special format requirements (numbers, special chars optional)

---

## Test Scenarios

### ✅ Scenario 1: Full Student Registration
```dart
// WHAT: Register a student with complete information
// WHEN: Student has all information including university details
// RESULT: Should register successfully

final form = {
  'email': 'student@dental.com',
  'firstName': 'John',
  'lastName': 'Doe',
  'userId': 'STU001',
  'cnic': '12345-6789012-3',
  'address': '123 Main St, City',
  'highestEducation': 'Undergraduate',
  'role': 'Student',
  'university': 'Dental University',          // PROVIDED
  'yearOfStudy': '3rd Year',                  // PROVIDED
  'batchCode': 'BATCH2023',                   // PROVIDED
};

await authProvider.register(form, 'password123');

✅ Success: User is registered
```

### ✅ Scenario 2: Minimal Student Registration
```dart
// WHAT: Register a student with only required fields
// WHEN: Student hasn't filled in university/year/batch fields
// RESULT: Should register successfully with empty optional fields

final form = {
  'email': 'student@dental.com',
  'firstName': 'Jane',
  'lastName': 'Smith',
  'userId': 'STU002',
  'cnic': '98765-4321098-7',
  'address': '456 Oak Ave, City',
  'highestEducation': 'Postgraduate',
  // university: NOT PROVIDED (defaults to '')
  // yearOfStudy: NOT PROVIDED (defaults to '')
  // batchCode: NOT PROVIDED (defaults to '')
};

await authProvider.register(form, 'securePassword456');

✅ Success: User is registered with empty optional fields
```

### ✅ Scenario 3: Partial Student Registration
```dart
// WHAT: Register a student with some optional fields
// WHEN: Student provides university and year but not batch code
// RESULT: Should register successfully with batchCode as empty

final form = {
  'email': 'student@dental.com',
  'firstName': 'Alex',
  'lastName': 'Johnson',
  'userId': 'STU003',
  'cnic': '11111-2222222-3',
  'address': '789 Pine Rd, City',
  'highestEducation': 'Undergraduate',
  'role': 'Student',
  'university': 'National Dental College',    // PROVIDED
  'yearOfStudy': '2nd Year',                  // PROVIDED
  // batchCode: NOT PROVIDED (defaults to '')
};

await authProvider.register(form, 'mixedFields789');

✅ Success: User is registered
  - university = 'National Dental College'
  - yearOfStudy = '2nd Year'
  - batchCode = '' (empty)
```

### ✅ Scenario 4: Dentist Registration
```dart
// WHAT: Register a dentist (no student fields needed)
// WHEN: Dentist registers for professional account
// RESULT: Should register successfully with empty optional fields

final form = {
  'email': 'dentist@clinic.com',
  'firstName': 'Dr.',
  'lastName': 'Williams',
  'userId': 'DENT001',
  'cnic': '55555-6666666-7',
  'address': 'Clinical Suite 100',
  'highestEducation': 'Doctorate',
  'role': 'Dentist',
  // No student-specific fields
};

await authProvider.register(form, 'dentistPass123');

✅ Success: Dentist is registered
  - role = 'Dentist'
  - university = '' (empty)
  - yearOfStudy = '' (empty)
  - batchCode = '' (empty)
```

---

## ❌ Error Test Scenarios

### ❌ Missing Required Field: Email
```dart
final form = {
  'firstName': 'John',
  'lastName': 'Doe',
  'userId': 'STU001',
  'cnic': '12345-6789012-3',
  'address': '123 Main St',
  'highestEducation': 'Undergraduate',
  // email: MISSING
};

await authProvider.register(form, 'password123');

❌ Error: "Email is required"
```

### ❌ Invalid Email Format
```dart
final form = {
  'email': 'invalid-email-format',  // No @ or domain
  'firstName': 'John',
  'lastName': 'Doe',
  'userId': 'STU001',
  'cnic': '12345-6789012-3',
  'address': '123 Main St',
  'highestEducation': 'Undergraduate',
};

await authProvider.register(form, 'password123');

❌ Error: "Enter a valid email"
```

### ❌ Password Too Short
```dart
final form = {
  'email': 'john@dental.com',
  'firstName': 'John',
  'lastName': 'Doe',
  'userId': 'STU001',
  'cnic': '12345-6789012-3',
  'address': '123 Main St',
  'highestEducation': 'Undergraduate',
};

await authProvider.register(form, 'short');  // Only 5 characters

❌ Error: "Password must be at least 8 characters"
```

### ❌ Missing Professional ID
```dart
final form = {
  'email': 'john@dental.com',
  'firstName': 'John',
  'lastName': 'Doe',
  'userId': '',  // EMPTY
  'cnic': '12345-6789012-3',
  'address': '123 Main St',
  'highestEducation': 'Undergraduate',
};

await authProvider.register(form, 'password123');

❌ Error: "Professional ID is required"
```

### ❌ Missing First Name
```dart
final form = {
  'email': 'john@dental.com',
  'firstName': '',  // EMPTY
  'lastName': 'Doe',
  'userId': 'STU001',
  'cnic': '12345-6789012-3',
  'address': '123 Main St',
  'highestEducation': 'Undergraduate',
};

await authProvider.register(form, 'password123');

❌ Error: "First name is required"
```

### ❌ Missing Last Name
```dart
final form = {
  'email': 'john@dental.com',
  'firstName': 'John',
  'lastName': '',  // EMPTY
  'userId': 'STU001',
  'cnic': '12345-6789012-3',
  'address': '123 Main St',
  'highestEducation': 'Undergraduate',
};

await authProvider.register(form, 'password123');

❌ Error: "Last name is required"
```

### ❌ Missing CNIC/License
```dart
final form = {
  'email': 'john@dental.com',
  'firstName': 'John',
  'lastName': 'Doe',
  'userId': 'STU001',
  'cnic': '',  // EMPTY
  'address': '123 Main St',
  'highestEducation': 'Undergraduate',
};

await authProvider.register(form, 'password123');

❌ Error: "License / CNIC is required"
```

### ❌ Missing Address
```dart
final form = {
  'email': 'john@dental.com',
  'firstName': 'John',
  'lastName': 'Doe',
  'userId': 'STU001',
  'cnic': '12345-6789012-3',
  'address': '',  // EMPTY
  'highestEducation': 'Undergraduate',
};

await authProvider.register(form, 'password123');

❌ Error: "Practice address is required"
```

### ❌ Missing Highest Education
```dart
final form = {
  'email': 'john@dental.com',
  'firstName': 'John',
  'lastName': 'Doe',
  'userId': 'STU001',
  'cnic': '12345-6789012-3',
  'address': '123 Main St',
  'highestEducation': '',  // EMPTY
};

await authProvider.register(form, 'password123');

❌ Error: "Highest education is required"
```

---

## Whitespace Handling

The system automatically trims whitespace from all fields:

```dart
final form = {
  'email': '  student@dental.com  ',      // → 'student@dental.com'
  'firstName': '  John  ',                 // → 'John'
  'lastName': '  Doe  ',                   // → 'Doe'
  'userId': '  STU001  ',                  // → 'STU001'
  'cnic': '  12345-6789012-3  ',          // → '12345-6789012-3'
  'address': '  123 Main St  ',           // → '123 Main St'
  'highestEducation': '  Undergraduate  ', // → 'Undergraduate'
  'university': '  DU  ',                  // → 'DU'
  'yearOfStudy': '  3  ',                  // → '3'
  'batchCode': '  B-23  ',                 // → 'B-23'
};

✅ Success: All spaces are trimmed automatically
```

---

## Valid Email Formats

✅ Accepted:
- `user@example.com`
- `john.doe@university.ac.uk`
- `student+section@dental.org`
- `dr.ahmed@clinic.edu.pk`

❌ Rejected:
- `userexample.com` (missing @)
- `user@.com` (missing domain name)
- `user@domain` (missing TLD extension)
- `@domain.com` (missing username)

---

## Test Execution Commands

### Run All Tests
```bash
flutter test test/auth_provider_registration_test.dart
```

### Run Specific Test Group
```bash
flutter test test/auth_provider_registration_test.dart -k "Student Registration"
```

### Run Specific Test
```bash
flutter test test/auth_provider_registration_test.dart -k "Should successfully register student WITH optional fields"
```

### Run with Verbose Output
```bash
flutter test test/auth_provider_registration_test.dart -v
```

### Generate Coverage Report
```bash
flutter test test/auth_provider_registration_test.dart --coverage
```

---

## Key Takeaways

1. **Optional Fields**:
   - `university`, `yearOfStudy`, `batchCode` are optional
   - They default to empty strings if not provided
   - Students can register without them

2. **Required Fields**:
   - Email, firstName, lastName, userId, cnic, address, highestEducation are mandatory
   - Validation happens BEFORE Firebase calls
   - Clear error messages guide users

3. **Password Policy**:
   - Minimum 8 characters
   - No complexity requirements

4. **Input Sanitization**:
   - All fields are trimmed of whitespace
   - Empty after trimming = invalid (for required fields)

5. **Error Handling**:
   - Validation errors thrown immediately
   - Loading state properly managed
   - No partial registrations

6. **Role-Based**:
   - Students can provide university info
   - Dentists don't need student-specific fields
   - Both can register successfully
