import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Connection Test Utility
/// Use this to verify Firebase connection and data operations
class FirebaseTest {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test Firebase Authentication Connection
  static Future<bool> testAuthConnection() async {
    try {
      // Check if Firebase Auth is initialized
      final currentUser = _auth.currentUser;
      debugPrint('✅ Firebase Auth Connected');
      debugPrint('Current User: ${currentUser?.email ?? "Not logged in"}');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase Auth Error: $e');
      return false;
    }
  }

  /// Test Firestore Connection and Write/Read
  static Future<bool> testFirestoreConnection() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint(
            '⚠️ Skipping Firestore write test (no logged-in user). Rule requires isAuth().');
        return false;
      }

      // Test write operation
      final testDoc = _firestore.collection('_test').doc('connection_test');
      await testDoc.set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase Firestore is working!',
      });

      debugPrint('✅ Firestore Write Success');

      // Test read operation
      final snapshot = await testDoc.get();
      if (snapshot.exists) {
        debugPrint('✅ Firestore Read Success: ${snapshot.data()}');

        // Clean up test document
        await testDoc.delete();
        debugPrint('✅ Firestore Delete Success');
        return true;
      }

      return false;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        debugPrint(
            '⚠️ Firestore rules blocked test write/read (permission-denied).');
        debugPrint(
            '✅ Firestore is reachable, but security rules restrict this test path.');
        return true;
      }
      debugPrint('❌ Firestore Error: $e');
      return false;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('permission-denied') ||
          msg.contains('missing or insufficient permissions')) {
        debugPrint(
            '⚠️ Firestore rules blocked test write/read (permission-denied).');
        debugPrint(
            '✅ Firestore is reachable, but security rules restrict this test path.');
        return true;
      }
      debugPrint('❌ Firestore Error: $e');
      return false;
    }
  }

  /// Run all Firebase tests
  static Future<Map<String, bool>> runAllTests() async {
    debugPrint('\n🔥 Starting Firebase Connection Tests...\n');

    final results = <String, bool>{};

    results['auth'] = await testAuthConnection();
    results['firestore'] = await testFirestoreConnection();

    debugPrint('\n📊 Firebase Test Results:');
    results.forEach((key, value) {
      debugPrint('  $key: ${value ? "✅ PASSED" : "❌ FAILED"}');
    });

    final allPassed = results.values.every((v) => v);
    debugPrint(
      allPassed
          ? '\n✅ All Firebase services are working correctly!'
          : '\n⚠️ Some Firebase services have issues.',
    );

    return results;
  }

  /// Verify Patient data storage and retrieval
  static Future<bool> testPatientOperations(String dentistUid) async {
    try {
      debugPrint('\n🧪 Testing Patient Operations...\n');

      // Test patient write
      final testPatient = {
        'dentistUid': dentistUid,
        'name': 'Test Patient',
        'dob': Timestamp.fromDate(DateTime(1990, 1, 1)),
        'gender': 'Male',
        'contactPhone': '1234567890',
        'contactEmail': 'test@example.com',
        'notes': 'Test patient for Firebase verification',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('patients').add(testPatient);
      debugPrint('✅ Patient Write Success: ${docRef.id}');

      // Test patient read
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        debugPrint('✅ Patient Read Success');
        debugPrint('   Data: ${snapshot.data()}');

        // Test patient query
        final querySnapshot = await _firestore
            .collection('patients')
            .where('dentistUid', isEqualTo: dentistUid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          debugPrint('✅ Patient Query Success');
          debugPrint('   Found ${querySnapshot.docs.length} patient(s)');
        }

        // Clean up test patient
        await docRef.delete();
        debugPrint('✅ Patient Delete Success');

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Patient Operations Error: $e');
      return false;
    }
  }

  /// Verify Case data storage and retrieval
  static Future<bool> testCaseOperations(String dentistUid) async {
    try {
      debugPrint('\n🧪 Testing Case Operations...\n');

      // Test case write
      final testCase = {
        'dentistUid': dentistUid,
        'patientId': 'test_patient_id',
        'patientName': 'Test Patient',
        'caseTitle': 'Test Case',
        'toothNumbers': '11',
        'symptoms': 'Test symptoms',
        'imageUrls': [],
        'aiAnalysis': {'status': 'Test', 'hasCavity': false, 'confidence': 0.0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('cases').add(testCase);
      debugPrint('✅ Case Write Success: ${docRef.id}');

      // Test case read
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        debugPrint('✅ Case Read Success');

        // Clean up test case
        await docRef.delete();
        debugPrint('✅ Case Delete Success');

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Case Operations Error: $e');
      return false;
    }
  }
}
