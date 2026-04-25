/*
  Flutter Web Register Page (MVC pattern)
  - Supports both Dentist/Doctor and Student roles
  - Student role hides professional fields and shows student fields
  - Dentist role shows professional fields
*/

import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_auth_flow_screens.dart';
import '../provider/auth_provider.dart';
import '../utils/app_dialogs.dart';
import '../utils/global_error_handler.dart';
import '../widgets/loaders/app_loader.dart';
import '../widgets/loading_button.dart';
import '../../providers/loading_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String _selectedRole = 'Student';

  // Dentist-specific
  final _userId = TextEditingController();
  final _cnic = TextEditingController();
  final _address = TextEditingController();
  final _highestEducation = TextEditingController();

  // Student-specific
  final _university = TextEditingController();
  final _studentId = TextEditingController();
  final _yearOfStudy = TextEditingController();
  final _batchCode = TextEditingController();

  static const List<String> _studyYears = [
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Year 5',
    'House Job',
  ];

  late final AnimationController _auraController;
  late final AnimationController _formIntroController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final role = args?['role'] as String?;
      if (role != null && (role == 'Student' || role == 'Dentist')) {
        setState(() => _selectedRole = role);
      }
    });

    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _formIntroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _formIntroController.forward();
  }

  @override
  void dispose() {
    _auraController.dispose();
    _formIntroController.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _userId.dispose();
    _cnic.dispose();
    _address.dispose();
    _highestEducation.dispose();
    _university.dispose();
    _studentId.dispose();
    _yearOfStudy.dispose();
    _batchCode.dispose();
    super.dispose();
  }

  bool get _isStudent => _selectedRole == 'Student';

  Future<void> _submit(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      AppDialogs.showWarningDialog(
        context,
        title: 'Missing Fields',
        message: 'Please fill in all required fields.',
        confirmLabel: 'OK',
        onConfirm: () {},
      );
      return;
    }

    final form = <String, String>{
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': _email.text.trim(),
      'role': _selectedRole,
    };

    if (_isStudent) {
      // Student fields — use student-specific fields, fill professional ones with defaults
      form['userId'] = _studentId.text.trim().isNotEmpty
          ? _studentId.text.trim()
          : 'STU-${DateTime.now().millisecondsSinceEpoch}';
      form['cnic'] = 'N/A';
      form['address'] =
          _university.text.trim().isNotEmpty ? _university.text.trim() : 'N/A';
      form['highestEducation'] = _yearOfStudy.text.trim().isNotEmpty
          ? 'Year ${_yearOfStudy.text.trim()}'
          : 'Undergraduate';
      form['university'] = _university.text.trim();
      form['yearOfStudy'] = _yearOfStudy.text.trim();
      form['batchCode'] = _batchCode.text.trim();
    } else {
      // Dentist fields
      form['userId'] = _userId.text.trim();
      form['cnic'] = _cnic.text.trim();
      form['address'] = _address.text.trim();
      form['highestEducation'] = _highestEducation.text.trim();
    }

    final password = _password.text.trim();

    try {
      await auth.register(form, password).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const EmailVerificationScreen(),
              settings:
                  RouteSettings(arguments: {'email': _email.text.trim()})));
    } on TimeoutException catch (_) {
      if (!mounted) return;
      AppDialogs.showErrorDialog(context,
          message:
              "The request timed out. Check your connection and try again.");
    } on SocketException catch (_) {
      if (!mounted) return;
      AppDialogs.showNoInternetDialog(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      AppDialogs.showErrorDialog(context,
          message: e.message ?? 'Registration failed.');
    } catch (error, stack) {
      if (!mounted) return;
      final errStr = error.toString();
      if (errStr.contains('firebase_auth') || errStr.contains('Exception:')) {
        final message = error is Exception
            ? errStr.replaceFirst('Exception: ', '')
            : 'Validation error occurred.';
        AppDialogs.showErrorDialog(context, message: message);
      } else {
        GlobalErrorHandler.instance.handleError(error, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) => Stack(
          children: [
            _AnimatedAura(controller: _auraController),
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildCard(auth),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(AuthProvider auth) {
    final colorScheme = Theme.of(context).colorScheme;
    final curvedAnimation = CurvedAnimation(
      parent: _formIntroController,
      curve: Curves.easeOutCubic,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.14),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER ---
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.0,
                child: _buildHeader(context),
              ),
              const SizedBox(height: 28),

              // --- ROLE SELECTOR ---
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.08,
                child: _buildRoleSelector(),
              ),
              const SizedBox(height: 24),

              // --- SECTION 1: ACCOUNT DETAILS ---
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.1,
                child: _buildSectionHeader('1. Account Details'),
              ),
              const SizedBox(height: 16),
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.15,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledTextField(
                        controller: _firstName,
                        label: 'First name',
                        hintText: 'John',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Enter your first name' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LabeledTextField(
                        controller: _lastName,
                        label: 'Last name',
                        hintText: 'Doe',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Enter your last name' : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.2,
                child: _LabeledTextField(
                  controller: _email,
                  label: 'Email address',
                  hintText: _isStudent
                      ? 'your.name@university.edu'
                      : 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Enter your email';
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(text)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.25,
                child: _buildPasswordFields(),
              ),
              const SizedBox(height: 28),

              // --- SECTION 2: ROLE-SPECIFIC INFORMATION ---
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.35,
                child: _buildSectionHeader(
                  _isStudent
                      ? '2. Student Information'
                      : '2. Professional Information',
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.4,
                child:
                    _isStudent ? _buildStudentFields() : _buildDentistFields(),
              ),

              const SizedBox(height: 28),

              // --- BUTTONS ---
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.55,
                child: Consumer<LoadingProvider>(
                  builder: (context, loadingState, _) {
                    return LoadingButton(
                      isLoading: auth.loading || loadingState.isLoading,
                      child: ElevatedButton(
                        onPressed: (auth.loading || loadingState.isLoading)
                            ? null
                            : () => loadingState
                                .runAsyncAction(() async => _submit(auth)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: colorScheme.onTertiary,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: auth.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: AppLoader(size: 20),
                              )
                            : Text(_isStudent
                                ? 'Create Student Account'
                                : 'Create Doctor/Dentist Account'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.6,
                child: TextButton(
                  onPressed: auth.loading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Back to login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final roleColor = _isStudent ? colorScheme.tertiary : colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: roleColor.withValues(alpha: 0.1),
          ),
          child: Icon(
            _isStudent ? Icons.school_outlined : Icons.group_work_outlined,
            color: roleColor,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isStudent ? 'Join as a Student' : 'Join as Doctor/Dentist',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isStudent
              ? 'Create your student account to take quizzes and track your progress.'
              : 'Create your professional account to manage quizzes, patients, and cases.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _RoleTab(
              icon: Icons.medical_services_outlined,
              label: 'Doctor/Dentist',
              isSelected: !_isStudent,
              color: colorScheme.primary,
              onTap: () => setState(() => _selectedRole = 'Dentist'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _RoleTab(
              icon: Icons.school_outlined,
              label: 'Student',
              isSelected: _isStudent,
              color: colorScheme.tertiary,
              onTap: () => setState(() => _selectedRole = 'Student'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        _PasswordTextField(
          controller: _password,
          label: 'Create password',
          hintText: '••••••••',
          validator: (value) {
            final text = value ?? '';
            if (text.isEmpty) return 'Enter a password';
            final hasUpper = RegExp(r'[A-Z]').hasMatch(text);
            final hasNumber = RegExp(r'[0-9]').hasMatch(text);
            final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(text);
            if (text.length < 8 || !hasUpper || !hasNumber || !hasSpecial) {
              return 'Use 8+ chars with uppercase, number, special';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        _PasswordStrengthIndicator(passwordController: _password),
        const SizedBox(height: 16),
        _PasswordTextField(
          controller: _confirmPassword,
          label: 'Confirm password',
          hintText: '••••••••',
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Please confirm your password';
            if (text != _password.text.trim()) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStudentFields() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledTextField(
                controller: _university,
                label: 'University / College',
                hintText: 'e.g., King Edward Medical University',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Enter your university' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledTextField(
                controller: _studentId,
                label: 'Student / Roll Number',
                hintText: 'e.g., 2023-BDS-045',
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Enter your student ID';
                  if (!RegExp(r'^[a-zA-Z0-9\-_/]+$').hasMatch(value)) {
                    return 'Use letters, numbers, or -_/';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _studyYears.contains(_yearOfStudy.text)
                    ? _yearOfStudy.text
                    : null,
                decoration: const InputDecoration(labelText: 'Year of Study'),
                items: _studyYears
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text(year),
                        ))
                    .toList(),
                onChanged: (value) {
                  _yearOfStudy.text = value ?? '';
                },
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select year of study' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LabeledTextField(
          controller: _batchCode,
          label: 'Batch / Class Code',
          hintText: 'Provided by your teacher',
          textInputAction: TextInputAction.done,
          validator: (v) =>
              v!.trim().isEmpty ? 'Enter your batch/class code' : null,
        ),
      ],
    );
  }

  Widget _buildDentistFields() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledTextField(
                controller: _userId,
                label: 'Professional ID',
                hintText: 'Your professional ID',
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Enter your professional ID' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _LabeledTextField(
                controller: _cnic,
                label: 'CNIC / License number',
                hintText: 'Your license number',
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Enter your license number' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabeledTextField(
                controller: _address,
                label: 'Practice address',
                hintText: '123 Dental St, City',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Enter your practice address' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _LabeledTextField(
                controller: _highestEducation,
                label: 'Highest education',
                hintText: 'e.g., Doctor of Dental Surgery',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Enter your highest education' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

// ─── Role Tab Widget ───────────────────────────────────────────────────
class _RoleTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _RoleTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Password Text Field ──────────────────────────────────────────────
class _PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?) validator;

  const _PasswordTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.validator,
  });

  @override
  State<_PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<_PasswordTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return _LabeledTextField(
      controller: widget.controller,
      label: widget.label,
      hintText: widget.hintText,
      obscureText: _obscure,
      textInputAction: TextInputAction.next,
      validator: widget.validator,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.passwordController});

  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: passwordController,
      builder: (context, value, _) {
        final password = value.text;
        final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
        final hasNumber = RegExp(r'[0-9]').hasMatch(password);
        final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
        final longEnough = password.length >= 8;

        final score = [hasUpper, hasNumber, hasSpecial, longEnough]
            .where((e) => e)
            .length;
        final colorScheme = Theme.of(context).colorScheme;

        String label;
        Color color;
        if (score <= 1) {
          label = 'Weak';
          color = colorScheme.error;
        } else if (score <= 3) {
          label = 'Fair';
          color = colorScheme.tertiary;
        } else {
          label = 'Strong';
          color = colorScheme.primary;
        }

        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Password strength: $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

// ─── Labeled Text Field ──────────────────────────────────────────────
class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colorScheme.surfaceContainerLowest,
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Animated Form Field ─────────────────────────────────────────────
class _AnimatedFormField extends StatelessWidget {
  const _AnimatedFormField({
    required this.animation,
    required this.delay,
    required this.child,
  });

  final Animation<double> animation;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final intervalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(delay.clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
      ),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(intervalAnimation);

    return FadeTransition(
      opacity: intervalAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}

// ─── Animated Aura Background ────────────────────────────────────────
class _AnimatedAura extends StatelessWidget {
  const _AnimatedAura({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final wave = math.sin(controller.value * 2 * math.pi);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 80 + wave * 16,
              left: -120,
              child: _AuraCircle(
                diameter: 280,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.tertiary.withValues(alpha: 0.2),
                ],
              ),
            ),
            Positioned(
              top: 140,
              right: 160,
              child: Transform.rotate(
                angle: controller.value * 0.3,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.tertiary.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AuraCircle extends StatelessWidget {
  const _AuraCircle({required this.diameter, required this.colors});

  final double diameter;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors, center: Alignment.topLeft),
      ),
    );
  }
}
