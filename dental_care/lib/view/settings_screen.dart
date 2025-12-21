import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_debug_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Map<String, dynamic> _defaultSettings = {
    'notifications': {
      'caseAlerts': true,
      'weeklyReports': true,
      'productUpdates': false,
      'abnormalFindings': true,
    },
    'workspace': {
      'autoSync': true,
      'autosaveDrafts': true,
      'reviewChecklist': true,
      'doubleReadMode': false,
      'autoAssignToMe': true,
    },
    'aiAssist': {
      'detectionSensitivity': 75.0,
      'autoAnnotations': true,
      'triagePriority': 'balanced',
    },
    'privacy': {
      'anonymizeExports': true,
      'keepActivityLog': true,
      'loginAlerts': true,
      'offlineMode': false,
    },
  };

  final _nameController = TextEditingController();

  bool _isLoadingProfile = false;
  bool _isLoadingSettings = false;
  bool _isUpdatingProfile = false;
  bool _isSavingSettings = false;
  bool _isRunningChecks = false;
  bool _isExportingSnapshot = false;

  String? _userEmail;
  String? _userName;

  Map<String, dynamic> _settings = _deepCopy(_defaultSettings);
  Map<String, String> _connectivityStatus = {
    'auth': 'pending',
    'firestore': 'pending',
    'storage': 'pending',
  };
  Map<String, String> _connectivityMessages = {
    'auth': 'Not checked yet',
    'firestore': 'Not checked yet',
    'storage': 'Not checked yet',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Prominent card decoration matching your specification
  BoxDecoration get _prominentCardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade300, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 20,
        spreadRadius: 1,
        offset: const Offset(0, 6),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 1000;

                    if (isWide) {
                      final columnWidth = (constraints.maxWidth - 24) / 2;
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: columnWidth,
                                child: _buildProfileCard(),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: columnWidth,
                                child: _buildPracticeCard(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: columnWidth,
                                child: _buildNotificationCard(),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: columnWidth,
                                child: _buildDataPrivacyCard(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildConnectivityCard(),
                          if (const bool.fromEnvironment('dart.vm.product') ==
                              false) ...[
                            const SizedBox(height: 24),
                            _buildDeveloperCard(),
                          ],
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 24),
                        _buildPracticeCard(),
                        const SizedBox(height: 24),
                        _buildNotificationCard(),
                        const SizedBox(height: 24),
                        _buildDataPrivacyCard(),
                        const SizedBox(height: 24),
                        _buildConnectivityCard(),
                        if (const bool.fromEnvironment('dart.vm.product') ==
                            false) ...[
                          const SizedBox(height: 24),
                          _buildDeveloperCard(),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 24),

          if (_isLoadingProfile || _isLoadingSettings) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFF4A90E2)),
              ),
            ),
          ] else ...[
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Email field (disabled)
            TextFormField(
              initialValue: _userEmail ?? 'Loading...',
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                helperText: 'Email cannot be changed',
              ),
              enabled: false,
            ),
            const SizedBox(height: 32),

            // Update Profile button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdatingProfile ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isUpdatingProfile
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Update Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPracticeCard() {
    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.precision_manufacturing_outlined,
                color: Color(0xFF4A90E2),
              ),
              const SizedBox(width: 8),
              Text(
                'Clinical & AI Preferences',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Auto-assign new scans to me'),
            subtitle: const Text('Keep new uploads in your review queue'),
            value: _readBool(['workspace', 'autoAssignToMe'], fallback: true),
            onChanged: (v) =>
                _updateSetting(['workspace', 'autoAssignToMe'], v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Enable review checklist'),
            subtitle: const Text('Show pre-publish checks on every case'),
            value: _readBool(['workspace', 'reviewChecklist'], fallback: true),
            onChanged: (v) =>
                _updateSetting(['workspace', 'reviewChecklist'], v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Double-read mode'),
            subtitle: const Text('Flag cases that need a second reader'),
            value: _readBool(['workspace', 'doubleReadMode'], fallback: false),
            onChanged: (v) =>
                _updateSetting(['workspace', 'doubleReadMode'], v),
          ),
          const SizedBox(height: 12),
          Text(
            'Detection Sensitivity',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _readNum([
              'aiAssist',
              'detectionSensitivity',
            ], fallback: 75.0).clamp(0, 100).toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label:
                '${_readNum(['aiAssist', 'detectionSensitivity'], fallback: 75.0).round()}%',
            onChanged: (v) => setState(() {
              _settings = _setNestedValue(_settings, [
                'aiAssist',
                'detectionSensitivity',
              ], v);
            }),
            onChangeEnd: (v) =>
                _updateSetting(['aiAssist', 'detectionSensitivity'], v),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Balanced'),
                selected:
                    _readString([
                      'aiAssist',
                      'triagePriority',
                    ], fallback: 'balanced') ==
                    'balanced',
                onSelected: (_) =>
                    _updateSetting(['aiAssist', 'triagePriority'], 'balanced'),
              ),
              ChoiceChip(
                label: const Text('Recall-focused'),
                selected:
                    _readString([
                      'aiAssist',
                      'triagePriority',
                    ], fallback: 'balanced') ==
                    'recall',
                onSelected: (_) =>
                    _updateSetting(['aiAssist', 'triagePriority'], 'recall'),
              ),
              ChoiceChip(
                label: const Text('Precision-focused'),
                selected:
                    _readString([
                      'aiAssist',
                      'triagePriority',
                    ], fallback: 'balanced') ==
                    'precision',
                onSelected: (_) =>
                    _updateSetting(['aiAssist', 'triagePriority'], 'precision'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            title: const Text('Auto-apply AI annotations'),
            subtitle: const Text('Show overlays on images by default'),
            value: _readBool(['aiAssist', 'autoAnnotations'], fallback: true),
            onChanged: (v) =>
                _updateSetting(['aiAssist', 'autoAnnotations'], v),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF4A90E2),
              ),
              const SizedBox(width: 8),
              Text(
                'Notifications & Reporting',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Case alerts'),
            subtitle: const Text('Notify when a case is uploaded or updated'),
            value: _readBool(['notifications', 'caseAlerts'], fallback: true),
            onChanged: (v) =>
                _updateSetting(['notifications', 'caseAlerts'], v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Abnormal findings'),
            subtitle: const Text('Alerts for high-risk findings flagged by AI'),
            value: _readBool([
              'notifications',
              'abnormalFindings',
            ], fallback: true),
            onChanged: (v) =>
                _updateSetting(['notifications', 'abnormalFindings'], v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Weekly summary reports'),
            subtitle: const Text(
              'Email a digest of patients, cases, and scans',
            ),
            value: _readBool([
              'notifications',
              'weeklyReports',
            ], fallback: true),
            onChanged: (v) =>
                _updateSetting(['notifications', 'weeklyReports'], v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Product updates'),
            subtitle: const Text('Occasional releases and tips'),
            value: _readBool([
              'notifications',
              'productUpdates',
            ], fallback: false),
            onChanged: (v) =>
                _updateSetting(['notifications', 'productUpdates'], v),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPrivacyCard() {
    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF4A90E2),
              ),
              const SizedBox(width: 8),
              Text(
                'Data & Privacy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Anonymize exports'),
            subtitle: const Text('Remove patient identifiers in exports'),
            value: _readBool(['privacy', 'anonymizeExports'], fallback: true),
            onChanged: (v) =>
                _updateSetting(['privacy', 'anonymizeExports'], v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Keep activity log'),
            subtitle: const Text('Store audit events for reviews'),
            value: _readBool(['privacy', 'keepActivityLog'], fallback: true),
            onChanged: (v) => _updateSetting(['privacy', 'keepActivityLog'], v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Login alerts'),
            subtitle: const Text('Notify when a new device signs in'),
            value: _readBool(['privacy', 'loginAlerts'], fallback: true),
            onChanged: (v) => _updateSetting(['privacy', 'loginAlerts'], v),
          ),
          SwitchListTile.adaptive(
            title: const Text('Offline-safe mode'),
            subtitle: const Text('Keep local drafts if connectivity drops'),
            value: _readBool(['privacy', 'offlineMode'], fallback: false),
            onChanged: (v) => _updateSetting(['privacy', 'offlineMode'], v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExportingSnapshot ? null : _exportDataSnapshot,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                    _isExportingSnapshot
                        ? 'Exporting...'
                        : 'Export data snapshot',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSavingSettings ? null : _saveSettingsNow,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    _isSavingSettings ? 'Saving...' : 'Save settings',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Exports are copied to your clipboard as JSON with counts and metadata.',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityCard() {
    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                color: Color(0xFF4A90E2),
              ),
              const SizedBox(width: 8),
              Text(
                'Connectivity & Health',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statusChip(
                'Auth',
                _connectivityStatus['auth'] ?? 'pending',
                _connectivityMessages['auth'] ?? '',
              ),
              _statusChip(
                'Firestore',
                _connectivityStatus['firestore'] ?? 'pending',
                _connectivityMessages['firestore'] ?? '',
              ),
              _statusChip(
                'Storage',
                _connectivityStatus['storage'] ?? 'pending',
                _connectivityMessages['storage'] ?? '',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunningChecks ? null : _runConnectivityChecks,
              icon: const Icon(Icons.play_circle_fill),
              label: Text(
                _isRunningChecks
                    ? 'Running health checks...'
                    : 'Run Firebase connectivity checks',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Text(
                'Developer Tools',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirebaseDebugScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.cloud),
              label: const Text('Firebase Debug & Tests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Run connectivity, read/write, and storage validation in one place.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingProfile = true;
      _isLoadingSettings = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      setState(() {
        _userEmail = currentUser.email;
      });

      // Load user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userSettings =
            (userData['settings'] as Map?)?.cast<String, dynamic>() ?? {};

        setState(() {
          _userName = userData['name'] ?? '';
          _nameController.text = _userName ?? '';
          _settings = _deepMerge(_defaultSettings, userSettings);
        });
      } else {
        // If user document doesn't exist, create it with defaults
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
              'name': currentUser.displayName ?? '',
              'email': currentUser.email ?? '',
              'settings': _defaultSettings,
            });

        setState(() {
          _userName = currentUser.displayName ?? '';
          _nameController.text = _userName ?? '';
          _settings = _deepCopy(_defaultSettings);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isLoadingSettings = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Update user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'name': _nameController.text.trim()});

      setState(() {
        _userName = _nameController.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }

  Future<void> _updateSetting(List<String> path, dynamic value) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('No authenticated user');
      return;
    }

    setState(() {
      _settings = _setNestedValue(_settings, path, value);
      _isSavingSettings = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({'settings': _settings}, SetOptions(merge: true));
    } catch (e) {
      _showError('Failed to save setting: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSettings = false;
        });
      }
    }
  }

  Future<void> _saveSettingsNow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('No authenticated user');
      return;
    }

    setState(() {
      _isSavingSettings = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({'settings': _settings}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to save settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSettings = false;
        });
      }
    }
  }

  Future<void> _exportDataSnapshot() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showError('No authenticated user');
      return;
    }

    setState(() {
      _isExportingSnapshot = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final patientsSnap = await FirebaseFirestore.instance
          .collection('patients')
          .where('dentistUid', isEqualTo: currentUser.uid)
          .get();

      final casesSnap = await FirebaseFirestore.instance
          .collection('cases')
          .where('dentistUid', isEqualTo: currentUser.uid)
          .get();

      final payload = {
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': currentUser.uid,
        'user': userDoc.data() ?? {},
        'counts': {
          'patients': patientsSnap.docs.length,
          'cases': casesSnap.docs.length,
        },
        'settings': _settings,
      };

      final json = const JsonEncoder.withIndent('  ').convert(payload);
      await Clipboard.setData(ClipboardData(text: json));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Snapshot copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to export data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExportingSnapshot = false;
        });
      }
    }
  }

  Future<void> _runConnectivityChecks() async {
    setState(() {
      _isRunningChecks = true;
      _connectivityStatus = {
        'auth': 'pending',
        'firestore': 'pending',
        'storage': 'pending',
      };
      _connectivityMessages = {
        'auth': 'Checking...',
        'firestore': 'Checking...',
        'storage': 'Checking...',
      };
    });

    final user = FirebaseAuth.instance.currentUser;
    bool authOk = false;
    bool firestoreOk = false;
    bool storageOk = false;
    String authMsg = 'No authenticated user';
    String firestoreMsg = 'Not run';
    String storageMsg = 'Not run';

    if (user != null) {
      authOk = true;
      authMsg = 'Authenticated as ${user.email ?? user.uid}';

      try {
        await FirebaseFirestore.instance
            .collection('health_checks')
            .doc(user.uid)
            .set({
              'checkedAt': FieldValue.serverTimestamp(),
              'device': 'settings_screen',
            }, SetOptions(merge: true));

        final doc = await FirebaseFirestore.instance
            .collection('health_checks')
            .doc(user.uid)
            .get();
        firestoreOk = doc.exists;
        firestoreMsg = firestoreOk
            ? 'Firestore read/write OK'
            : 'Firestore write/read failed';
      } catch (e) {
        firestoreMsg = 'Firestore failed: $e';
      }

      try {
        final ref = FirebaseStorage.instance.ref().child(
          'health_checks/${user.uid}_ping.txt',
        );
        await ref.putData(Uint8List.fromList('ok'.codeUnits));
        await ref.delete();
        storageOk = true;
        storageMsg = 'Storage write/delete OK';
      } catch (e) {
        storageMsg = 'Storage failed: $e';
      }
    }

    if (mounted) {
      setState(() {
        _isRunningChecks = false;
        _connectivityStatus = {
          'auth': authOk ? 'pass' : 'fail',
          'firestore': firestoreOk ? 'pass' : 'fail',
          'storage': storageOk ? 'pass' : 'fail',
        };
        _connectivityMessages = {
          'auth': authMsg,
          'firestore': firestoreMsg,
          'storage': storageMsg,
        };
      });
    }

    if (!authOk) {
      _showError('Sign in to run connectivity checks.');
    } else if (!firestoreOk || !storageOk) {
      _showError('Some checks failed. Review the status chips.');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firebase connectivity looks good'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _statusChip(String label, String status, String message) {
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case 'pass':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'fail':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        icon = Icons.error;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: TextStyle(fontSize: 12, color: fg.withOpacity(0.9)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _readBool(List<String> path, {bool fallback = false}) {
    final value = _readSetting(path, fallback: fallback);
    return value is bool ? value : fallback;
  }

  num _readNum(List<String> path, {num fallback = 0}) {
    final value = _readSetting(path, fallback: fallback);
    if (value is num) return value;
    return fallback;
  }

  String _readString(List<String> path, {String fallback = ''}) {
    final value = _readSetting(path, fallback: fallback);
    if (value is String) return value;
    return fallback;
  }

  dynamic _readSetting(List<String> path, {dynamic fallback}) {
    dynamic current = _settings;
    for (final segment in path) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return fallback;
      }
    }
    return current ?? fallback;
  }

  Map<String, dynamic> _setNestedValue(
    Map<String, dynamic> source,
    List<String> path,
    dynamic value,
  ) {
    final result = Map<String, dynamic>.from(source);
    Map<String, dynamic> cursor = result;
    for (int i = 0; i < path.length; i++) {
      final key = path[i];
      final isLast = i == path.length - 1;
      if (isLast) {
        cursor[key] = value;
      } else {
        final existing = cursor[key];
        if (existing is Map<String, dynamic>) {
          final cloned = Map<String, dynamic>.from(existing);
          cursor[key] = cloned;
          cursor = cloned;
        } else if (existing is Map) {
          final cloned = Map<String, dynamic>.from(
            existing.map((k, v) => MapEntry(k.toString(), v)),
          );
          cursor[key] = cloned;
          cursor = cloned;
        } else {
          final newMap = <String, dynamic>{};
          cursor[key] = newMap;
          cursor = newMap;
        }
      }
    }
    return result;
  }

  Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final result = _deepCopy(base);
    override.forEach((key, value) {
      if (value is Map && result[key] is Map) {
        result[key] = _deepMerge(
          (result[key] as Map).cast<String, dynamic>(),
          value.cast<String, dynamic>(),
        );
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> input) {
    final output = <String, dynamic>{};
    input.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        output[key] = _deepCopy(value);
      } else if (value is Map) {
        output[key] = _deepCopy(value.cast<String, dynamic>());
      } else {
        output[key] = value;
      }
    });
    return output;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }
}
