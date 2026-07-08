// ignore_for_file: unused_field, unused_element

import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Firebase storage used for user settings
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// removed unused import
import 'package:provider/provider.dart';
import '../core/responsive/app_breakpoints.dart';
import '../core/theme/app_semantic_colors.dart';
import '../provider/auth_provider.dart';

import '../utils/app_dialogs.dart';
import '../utils/global_error_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Map<String, dynamic> _defaultSettings = {
    'notifications': {'caseAlerts': true, 'productUpdates': false},
    'privacy': {'loginAlerts': true},
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

  BoxDecoration get _prominentCardDecoration => BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.9),
                        Theme.of(context).colorScheme.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage notifications, privacy, and app preferences.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.settings,
                            color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoadingSettings) ...[
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 16),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        AppBreakpoints.fromWidth(constraints.maxWidth) ==
                                AppDeviceType.desktop ||
                            AppBreakpoints.fromWidth(constraints.maxWidth) ==
                                AppDeviceType.largeDesktop;

                    if (isWide) {
                      final columnWidth = (constraints.maxWidth - 24) / 2;
                      return Column(
                        children: [
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
                                child: _buildPrivacyCard(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: columnWidth,
                                child: _buildAppearanceCard(),
                              ),
                              const SizedBox(width: 24),
                              SizedBox(
                                width: columnWidth,
                                child: _buildAccountSecurityCard(),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _buildNotificationCard(),
                        const SizedBox(height: 24),
                        _buildPrivacyCard(),
                        const SizedBox(height: 24),
                        _buildAppearanceCard(),
                        const SizedBox(height: 24),
                        _buildAccountSecurityCard(),
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

  Widget _buildNotificationCard() {
    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
            title: const Text('App updates'),
            subtitle: const Text('Occasional releases and improvements'),
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

  Widget _buildAppearanceCard() {
    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.light_mode_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: const Text('Light theme'),
            subtitle: const Text(
              'Clinical blue & white palette, tuned for your role',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Active',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy & Security',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Login alerts'),
            subtitle: const Text('Notify when a new device signs in'),
            value: _readBool(['privacy', 'loginAlerts'], fallback: true),
            onChanged: (v) => _updateSetting(['privacy', 'loginAlerts'], v),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurityCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final danger = semantic?.danger ?? colorScheme.error;

    return Container(
      decoration: _prominentCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account & Security',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 24),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Delete Account Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Delete Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: danger,
                foregroundColor: colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: danger.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Deleting your account is permanent and cannot be undone. All your data will be deleted.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
    );

    if (confirmed != true || !mounted) return;

    // Go through AuthProvider so session storage and cached user data
    // are cleared too — a bare FirebaseAuth.signOut leaves them behind.
    final auth = context.read<AuthProvider>();
    try {
      await auth.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(
          context,
          message: 'Error logging out: $e',
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context,
      title: 'Delete Account',
      message:
          'This action is permanent and cannot be undone. All your data will be deleted. Enter your password to confirm.',
    );

    if (confirmed != true) return;

    if (!mounted) return;

    // Show password verification dialog
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    bool isDeleting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Theme.of(context).colorScheme.onError,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirm Account Deletion',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onError,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This cannot be undone',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onError
                                      .withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Please enter your email and password to confirm account deletion:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Email field
                        TextField(
                          controller: emailController,
                          enabled: !isDeleting,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password field
                        TextField(
                          controller: passwordController,
                          enabled: !isDeleting,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerLowest,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isDeleting
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDeleting
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isDeleting
                              ? null
                              : () async {
                                  final email = emailController.text.trim();
                                  final password = passwordController.text;

                                  if (email.isEmpty || password.isEmpty) {
                                    AppDialogs.showErrorDialog(
                                      context,
                                      message:
                                          'Please enter both email and password',
                                    );
                                    return;
                                  }

                                  setState(() => isDeleting = true);

                                  try {
                                    final currentUser =
                                        FirebaseAuth.instance.currentUser;
                                    if (currentUser == null) {
                                      throw Exception('No authenticated user');
                                    }

                                    // Re-authenticate user
                                    final credential =
                                        EmailAuthProvider.credential(
                                      email: email,
                                      password: password,
                                    );

                                    await currentUser
                                        .reauthenticateWithCredential(
                                            credential);

                                    // Delete Firestore user document
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(currentUser.uid)
                                        .delete();

                                    // Delete user account
                                    await currentUser.delete();

                                    if (mounted) {
                                      Navigator.pop(context);
                                      AppDialogs.showSuccessDialog(
                                        context,
                                        message:
                                            'Your account has been deleted successfully.',
                                      ).then((_) {
                                        if (mounted) {
                                          Navigator.of(context)
                                              .pushNamedAndRemoveUntil(
                                            '/',
                                            (route) => false,
                                          );
                                        }
                                      });
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    setState(() => isDeleting = false);
                                    if (mounted) {
                                      String message =
                                          'Error deleting account: ${e.message}';
                                      if (e.code == 'wrong-password') {
                                        message =
                                            'Incorrect password. Please try again.';
                                      } else if (e.code == 'user-mismatch') {
                                        message =
                                            'Email does not match the logged-in account.';
                                      } else if (e.code == 'invalid-email') {
                                        message = 'Invalid email address.';
                                      }
                                      AppDialogs.showErrorDialog(
                                        context,
                                        message: message,
                                      );
                                    }
                                  } catch (e) {
                                    setState(() => isDeleting = false);
                                    if (mounted) {
                                      AppDialogs.showErrorDialog(
                                        context,
                                        message: 'Error: $e',
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            foregroundColor:
                                Theme.of(context).colorScheme.onError,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: isDeleting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onError,
                                    ),
                                  ),
                                )
                              : const Text('Delete Account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    passwordController.dispose();
    emailController.dispose();
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

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .timeout(const Duration(seconds: 30));

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
        }).timeout(const Duration(seconds: 30));

        setState(() {
          _userName = currentUser.displayName ?? '';
          _nameController.text = _userName ?? '';
          _settings = _deepCopy(_defaultSettings);
        });
      }
    } on TimeoutException catch (_) {
      _showDialogAfterBuild(() {
        AppDialogs.showErrorDialog(context,
            message:
                "The request timed out. Check your connection and try again.");
      });
    } on SocketException catch (_) {
      _showDialogAfterBuild(() {
        AppDialogs.showNoInternetDialog(context);
      });
    } catch (e, stack) {
      _showDialogAfterBuild(() {
        GlobalErrorHandler.instance.handleError(e, stack);
      });
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
        SnackBar(
          content: const Text('Name cannot be empty'),
          backgroundColor:
              Theme.of(context).extension<AppSemanticColors>()?.danger ??
                  Theme.of(context).colorScheme.error,
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'name': _nameController.text.trim()}).timeout(
              const Duration(seconds: 30));

      setState(() {
        _userName = _nameController.text.trim();
      });

      if (mounted) {
        AppDialogs.showInfoDialog(
          context,
          title: 'Success',
          message: 'Profile updated successfully!',
        );
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        AppDialogs.showErrorDialog(context,
            message: "The request timed out. Check your connection.");
      }
    } on SocketException catch (_) {
      if (mounted) AppDialogs.showNoInternetDialog(context);
    } catch (e, stack) {
      if (mounted) GlobalErrorHandler.instance.handleError(e, stack);
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
          .set({'settings': _settings}, SetOptions(merge: true)).timeout(
              const Duration(seconds: 30));
    } on TimeoutException catch (_) {
      _showError('The request timed out. Check your connection.');
    } on SocketException catch (_) {
      if (mounted) AppDialogs.showNoInternetDialog(context);
    } catch (e, stack) {
      if (mounted) GlobalErrorHandler.instance.handleError(e, stack);
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
        AppDialogs.showInfoDialog(context,
            title: 'Success', message: 'Settings saved');
      }
    } catch (e) {
      _showError('Failed to save settings. Please try again.');
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
          .get()
          .timeout(const Duration(seconds: 30));

      final patientsSnap = await FirebaseFirestore.instance
          .collection('patients')
          .where('dentistUid', isEqualTo: currentUser.uid)
          .get()
          .timeout(const Duration(seconds: 30));

      final casesSnap = await FirebaseFirestore.instance
          .collection('cases')
          .where('dentistUid', isEqualTo: currentUser.uid)
          .get()
          .timeout(const Duration(seconds: 30));

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
        AppDialogs.showInfoDialog(context,
            title: 'Success', message: 'Data snapshot copied to clipboard!');
      }
    } catch (e) {
      _showError('Failed to export data. Please try again.');
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
        firestoreMsg = 'Firestore check failed. Please try again.';
      }

      try {
        // Supabase storage checks removed. Use Firebase Storage if needed.
        storageOk = true;
        storageMsg = 'Storage checks skipped (Supabase removed)';
      } catch (e) {
        storageMsg = 'Storage check skipped.';
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
        AppDialogs.showInfoDialog(context,
            title: 'Connectivity Check',
            message: 'All connections successful!');
      }
    }
  }

  bool _readBool(List<String> path, {bool fallback = false}) {
    final value = _readSetting(path, fallback: fallback);
    return value is bool ? value : fallback;
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
      AppDialogs.showErrorDialog(context, message: message);
    }
  }

  void _showDialogAfterBuild(VoidCallback action) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }
}
