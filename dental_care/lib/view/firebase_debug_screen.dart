import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/firebase_test.dart';
import '../provider/auth_provider.dart';

/// Debug screen to test Firebase operations
/// Access this from Settings or add to navigation for testing
class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({super.key});

  @override
  State<FirebaseDebugScreen> createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  Map<String, bool> _testResults = {};
  bool _isRunning = false;
  String _log = '';

  void _addLog(String message) {
    setState(() {
      _log +=
          '${DateTime.now().toIso8601String().split('T')[1].substring(0, 8)}: $message\n';
    });
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _log = '';
    });

    _addLog('🔥 Starting Firebase Tests...');

    try {
      final results = await FirebaseTest.runAllTests();
      setState(() {
        _testResults = results;
      });

      if (results.values.every((v) => v)) {
        _addLog('✅ All tests passed!');
      } else {
        _addLog('⚠️ Some tests failed. Check details above.');
      }
    } catch (e) {
      _addLog('❌ Error running tests: $e');
    }

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _testPatientOps() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.currentUserId;

    if (uid == null) {
      _addLog('❌ No authenticated user');
      return;
    }

    setState(() {
      _isRunning = true;
    });

    _addLog('🧪 Testing Patient Operations...');

    try {
      final result = await FirebaseTest.testPatientOperations(uid);
      if (result) {
        _addLog('✅ Patient operations successful');
      } else {
        _addLog('❌ Patient operations failed');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _testCaseOps() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.currentUserId;

    if (uid == null) {
      _addLog('❌ No authenticated user');
      return;
    }

    setState(() {
      _isRunning = true;
    });

    _addLog('🧪 Testing Case Operations...');

    try {
      final result = await FirebaseTest.testCaseOperations(uid);
      if (result) {
        _addLog('✅ Case operations successful');
      } else {
        _addLog('❌ Case operations failed');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Debug & Test'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Firebase Connection Tests',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test Firebase Auth, Firestore, and Storage connections',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Test Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runAllTests,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run All Tests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _testPatientOps,
                  icon: const Icon(Icons.person),
                  label: const Text('Test Patient Ops'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _testCaseOps,
                  icon: const Icon(Icons.medical_services),
                  label: const Text('Test Case Ops'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _log = '';
                      _testResults = {};
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Test Results
            if (_testResults.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      ..._testResults.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                entry.value ? Icons.check_circle : Icons.error,
                                color: entry.value ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${entry.key.toUpperCase()}: ${entry.value ? "PASSED" : "FAILED"}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: entry.value
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Log Display
            Card(
              child: Container(
                width: double.infinity,
                height: 400,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty
                        ? 'No logs yet. Run tests to see results.'
                        : _log,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const Text(
                      '1. Run All Tests - Tests Firebase connection\n'
                      '2. Test Patient Ops - Tests patient CRUD operations\n'
                      '3. Test Case Ops - Tests case CRUD operations\n'
                      '4. Check the log for detailed results\n'
                      '5. All tests should show ✅ PASSED\n\n'
                      'If any test fails:\n'
                      '• Check Firebase Console for security rules\n'
                      '• Verify internet connection\n'
                      '• Check browser console for errors',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
