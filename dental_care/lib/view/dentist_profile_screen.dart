import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:image_picker/image_picker.dart';
import '../provider/auth_provider.dart';
import '../core/animation_constants.dart';
import '../core/theme/app_semantic_colors.dart';
import '../utils/app_dialogs.dart';
import '../widgets/loaders/app_loader.dart';

class DentistProfileScreen extends StatefulWidget {
  const DentistProfileScreen({super.key});

  @override
  State<DentistProfileScreen> createState() => _DentistProfileScreenState();
}

class _DentistProfileScreenState extends State<DentistProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isEditingProfile = false;
  bool _isUploadingPhoto = false;
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _profileImageUrl;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: AppCurves.smooth),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: AppCurves.enter),
    );
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _specializationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data();
            _profileImageUrl = _userData?['photoUrl'];
            _nameController.text =
                '${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? ''}'
                    .trim();
            _specializationController.text = _userData?['specialization'] ?? '';
            _phoneController.text = _userData?['phone'] ?? '';
            _addressController.text = _userData?['address'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingPhoto = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Upload to Supabase Storage
      final supabase = Supabase.instance.client;
      const bucket = 'profile_photos';
      final path = '${currentUser.uid}.jpg';

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await supabase.storage.from(bucket).uploadBinary(path, bytes);
      } else {
        await supabase.storage.from(bucket).upload(path, File(image.path));
      }

      final downloadUrl = supabase.storage.from(bucket).getPublicUrl(path);

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'photoUrl': downloadUrl});

      if (mounted) {
        setState(() {
          _profileImageUrl = downloadUrl;
          _isUploadingPhoto = false;
        });
        AppDialogs.showInfoDialog(context,
            title: 'Success', message: 'Profile photo updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        AppDialogs.showErrorDialog(
          context,
          message: 'Unable to upload photo right now. Please try again.',
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'firstName': firstName,
        'lastName': lastName,
        'specialization': _specializationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });

      if (mounted) {
        setState(() => _isEditingProfile = false);
        AppDialogs.showInfoDialog(context,
            title: 'Success', message: 'Profile updated successfully');
        _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(
          context,
          message: 'Unable to update profile right now. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RepaintBoundary(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RepaintBoundary(
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage your account and preferences',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (!_isEditingProfile)
                          ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => _isEditingProfile = true),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Profile Info Card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar with edit button
                          Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.primary,
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _isUploadingPhoto
                                      ? const Center(child: AppLoader(size: 56))
                                      : _profileImageUrl != null
                                          ? Image.network(
                                              _profileImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _buildAvatarFallback(),
                                            )
                                          : _buildAvatarFallback(),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: _isUploadingPhoto
                                      ? null
                                      : _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.shadow
                                              .withValues(alpha: 0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: colorScheme.onPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Name and Email
                          if (_isEditingProfile) ...[
                            _buildEditField(
                              'Full Name',
                              _nameController,
                              Icons.person,
                            ),
                            const SizedBox(height: 16),
                            _buildEditField(
                              'Specialization',
                              _specializationController,
                              Icons.medical_services,
                            ),
                            const SizedBox(height: 16),
                            _buildEditField(
                                'Phone', _phoneController, Icons.phone),
                            const SizedBox(height: 16),
                            _buildEditField(
                              'Address',
                              _addressController,
                              Icons.location_on,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() => _isEditingProfile = false);
                                      _loadUserData();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _updateProfile,
                                    child: const Text('Save Changes'),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              _nameController.text.isNotEmpty
                                  ? 'Dr. ${_nameController.text}'
                                  : 'Dr. User',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (_specializationController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _specializationController.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currentUser?.email ?? 'No email',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (_phoneController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _phoneController.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistics Row
                    _buildStatisticsSection(),
                    const SizedBox(height: 24),

                    // Account Information
                    _buildAccountInfoSection(currentUser),
                    const SizedBox(height: 24),

                    // Actions Section
                    _buildActionsSection(authProvider),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          color: colorScheme.primary.withValues(alpha: 0.1),
          child: Center(
            child: Text(
              authProvider.initials,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    if (currentUser == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Patients',
                Icons.people,
                semanticColors?.info ?? colorScheme.primary,
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('patients')
                      .where('dentistUid', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text('...');
                    return Text(
                      '${snapshot.data!.docs.length}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: semanticColors?.info ?? colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Cases',
                Icons.folder,
                semanticColors?.warning ?? colorScheme.tertiary,
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('cases')
                      .where('dentistUid', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text('...');
                    return Text(
                      '${snapshot.data!.docs.length}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: semanticColors?.warning ?? colorScheme.tertiary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Quizzes',
                Icons.quiz,
                semanticColors?.success ?? colorScheme.secondary,
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('quizzes')
                      .where('dentistUid', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text('...');
                    return Text(
                      '${snapshot.data!.docs.length}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: semanticColors?.success ?? colorScheme.secondary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    IconData icon,
    Color color,
    Widget valueWidget,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          valueWidget,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection(User? currentUser) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('User ID', currentUser?.uid.substring(0, 12) ?? 'N/A'),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Account Created',
            _formatDate(currentUser?.metadata.creationTime),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Last Sign In',
            _formatDate(currentUser?.metadata.lastSignInTime),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Email Verified',
            currentUser?.emailVerified == true ? 'Yes ✓' : 'No',
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(AuthProvider authProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            'Change Password',
            'Update your account password',
            Icons.lock_outline,
            semanticColors?.warning ?? colorScheme.tertiary,
            () => _showChangePasswordDialog(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Export Data',
            'Download your account data',
            Icons.download,
            semanticColors?.info ?? colorScheme.primary,
            () => _exportUserData(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Delete Account',
            'Permanently delete your account',
            Icons.delete_outline,
            semanticColors?.danger ?? colorScheme.error,
            () => _showDeleteAccountDialog(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logout(authProvider),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: semanticColors?.danger ?? colorScheme.error,
                foregroundColor: colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _logout(AuthProvider authProvider) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change Password'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        if (newPasswordController.text != confirmPasswordController.text) {
          throw 'Passwords do not match';
        }

        if (newPasswordController.text.length < 6) {
          throw 'Password must be at least 6 characters';
        }

        // Re-authenticate
        final credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: currentPasswordController.text,
        );
        await currentUser.reauthenticateWithCredential(credential);

        // Change password
        await currentUser.updatePassword(newPasswordController.text);

        if (mounted) {
          AppDialogs.showInfoDialog(context,
              title: 'Success', message: 'Password changed successfully');
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showErrorDialog(
            context,
            message: 'Unable to change password right now. Please try again.',
          );
        }
      }
    }

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _exportUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparing your data export...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Fetch user data
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final patients = await FirebaseFirestore.instance
          .collection('patients')
          .where('dentistUid', isEqualTo: currentUser.uid)
          .get();

      final cases = await FirebaseFirestore.instance
          .collection('cases')
          .where('dentistUid', isEqualTo: currentUser.uid)
          .get();

      // Create export data
      final exportData = {
        'user': userData.data(),
        'patients_count': patients.docs.length,
        'cases_count': cases.docs.length,
        'export_date': DateTime.now().toIso8601String(),
      };

      if (mounted) {
        AppDialogs.showInfoDialog(context,
            title: 'Success',
            message: 'Data exported: ${exportData.toString()}');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(
          context,
          message: 'Unable to export data right now. Please try again.',
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final passwordController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '⚠️ This action is irreversible. All your data will be permanently deleted.',
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: semanticColors?.danger ?? colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        // Re-authenticate
        final credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: passwordController.text,
        );
        await currentUser.reauthenticateWithCredential(credential);

        // Delete user data from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .delete();

        // Delete account
        await currentUser.delete();

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showErrorDialog(
            context,
            message: 'Unable to delete account right now. Please try again.',
          );
        }
      }
    }

    passwordController.dispose();
  }
}
