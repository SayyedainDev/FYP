import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Student Registration - Validation', () {
    void expectThrows(Map<String, String> form, String password) {
      expect(() => _validateRegistrationForm(form, password), throwsException);
    }

    test('missing email throws', () {
      final form = {
        'firstName': 'John',
        'lastName': 'Doe',
        'userId': 'STU001',
        'cnic': '12345-6789012-3',
        'address': '123 Main St',
        'highestEducation': 'Undergraduate',
      };
      expectThrows(form, 'password123');
    });

    test('invalid email throws', () {
      final form = {
        'email': 'invalid-email',
        'firstName': 'John',
        'lastName': 'Doe',
        'userId': 'STU001',
        'cnic': '12345-6789012-3',
        'address': '123 Main St',
        'highestEducation': 'Undergraduate',
      };
      expectThrows(form, 'password123');
    });

    test('short password throws', () {
      final form = {
        'email': 'student@dental.com',
        'firstName': 'John',
        'lastName': 'Doe',
        'userId': 'STU001',
        'cnic': '12345-6789012-3',
        'address': '123 Main St',
        'highestEducation': 'Undergraduate',
      };
      expectThrows(form, 'short');
    });

    test('valid minimal form passes', () {
      final form = {
        'email': 'student@dental.com',
        'firstName': 'Jane',
        'lastName': 'Smith',
        'userId': 'STU002',
        'cnic': '98765-4321098-7',
        'address': '456 Oak Ave',
        'highestEducation': 'Postgraduate',
      };
      _validateRegistrationForm(form, 'securePassword456');
    });
  });
}

void _validateRegistrationForm(Map<String, String> form, String password) {
  final email = form['email']?.trim() ?? '';
  final firstName = form['firstName']?.trim() ?? '';
  final lastName = form['lastName']?.trim() ?? '';
  final userId = form['userId']?.trim() ?? '';
  final cnic = form['cnic']?.trim() ?? '';
  final address = form['address']?.trim() ?? '';
  final highestEducation = form['highestEducation']?.trim() ?? '';

  if (userId.isEmpty) throw Exception('Professional ID is required');
  if (firstName.isEmpty) throw Exception('First name is required');
  if (lastName.isEmpty) throw Exception('Last name is required');
  if (cnic.isEmpty) throw Exception('License / CNIC is required');
  if (address.isEmpty) throw Exception('Practice address is required');
  if (highestEducation.isEmpty)
    throw Exception('Highest education is required');
  if (email.isEmpty) throw Exception('Email is required');

  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(email)) throw Exception('Enter a valid email');

  if (password.trim().length < 8) {
    throw Exception('Password must be at least 8 characters');
  }
}
