/*
  Flutter Web Register Page (MVC pattern)
  - This is the View layer.
  - Use Provider (AuthProvider) for state management.
  - Form Fields:
      userId, firstName, lastName, cnic, address, highestEducation, email, password, confirmPassword
  - Validation for required fields & password match
  - On "Submit", call AuthProvider.register(formData, password)
  - If loading, show CircularProgressIndicator
  - After successful registration, navigate to '/upload'
  - Use a blue and white theme consistent with the Dentist AI project
  - Keep code modular and readable
  - UI Layout matches user-provided image (external labels, sections)
*/

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart'; // Ensure this path is correct

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userId = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _cnic = TextEditingController();
  final _address = TextEditingController();
  final _highestEducation = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  late final AnimationController _auraController;
  late final AnimationController _formIntroController;

  @override
  void initState() {
    super.initState();
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
    _userId.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _cnic.dispose();
    _address.dispose();
    _highestEducation.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final form = <String, String>{
      'userId': _userId.text.trim(),
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'cnic': _cnic.text.trim(),
      'address': _address.text.trim(),
      'highestEducation': _highestEducation.text.trim(),
      'email': _email.text.trim(),
    };
    final password = _password.text.trim();

    try {
      await auth.register(form, password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (error) {
      if (!mounted) return;
      final message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Unexpected error occurred.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $message'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
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
                  child: _RegisterCard(
                    formKey: _formKey,
                    userId: _userId,
                    firstName: _firstName,
                    lastName: _lastName,
                    cnic: _cnic,
                    address: _address,
                    highestEducation: _highestEducation,
                    email: _email,
                    password: _password,
                    confirmPassword: _confirmPassword,
                    introAnimation: _formIntroController,
                    auth: auth,
                    onSubmit: () => _submit(auth),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// --- The Main Registration Card Widget ---
//
class _RegisterCard extends StatefulWidget {
  const _RegisterCard({
    required this.formKey,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.cnic,
    required this.address,
    required this.highestEducation,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.introAnimation,
    required this.auth,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController userId;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController cnic;
  final TextEditingController address;
  final TextEditingController highestEducation;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final Animation<double> introAnimation;
  final AuthProvider auth;
  final VoidCallback onSubmit;

  @override
  State<_RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<_RegisterCard> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: widget.introAnimation,
      curve: Curves.easeOutCubic,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x230A2142),
            blurRadius: 32,
            spreadRadius: 2,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        child: Form(
          key: widget.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER (Icon, Title, Subtitle) ---
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.0,
                child: _buildHeader(context),
              ),
              const SizedBox(height: 28),

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
                        controller: widget.firstName,
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
                        controller: widget.lastName,
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
                  controller: widget.email,
                  label: 'Email address',
                  hintText: 'you@example.com',
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
                child: _LabeledTextField(
                  controller: widget.password,
                  label: 'Create password',
                  hintText: '********',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) return 'Enter a password';
                    if (text.length < 8) return 'Use at least 8 characters';
                    return null;
                  },
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _obscurePassword = !_obscurePassword;
                    }),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.3,
                child: _LabeledTextField(
                  controller: widget.confirmPassword,
                  label: 'Confirm password',
                  hintText: '********',
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Please confirm your password';
                    if (text != widget.password.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }),
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // --- SECTION 2: PROFESSIONAL INFORMATION ---
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.35,
                child: _buildSectionHeader('2. Professional Information'),
              ),
              const SizedBox(height: 16),
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.4,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledTextField(
                        controller: widget.userId,
                        label: 'Professional ID',
                        hintText: 'Your professional ID',
                        textInputAction: TextInputAction.next,
                        validator: (v) => v!.trim().isEmpty
                            ? 'Enter your professional ID'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LabeledTextField(
                        controller: widget.cnic,
                        label: 'CNIC / License number',
                        hintText: 'Your license number',
                        textInputAction: TextInputAction.next,
                        validator: (v) => v!.trim().isEmpty
                            ? 'Enter your license number'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- THIS IS THE CORRECTED SECTION ---
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.45,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledTextField(
                        controller: widget.address,
                        label: 'Practice address',
                        hintText: '123 Dental St, City',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v!.trim().isEmpty
                            ? 'Enter your practice address'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _LabeledTextField(
                        controller: widget.highestEducation,
                        label: 'Highest education',
                        hintText: 'e.g., Doctor of Dental Surgery',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        validator: (v) => v!.trim().isEmpty
                            ? 'Enter your highest education'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // --- END OF CORRECTION ---
              const SizedBox(height: 28),

              // --- BUTTONS ---
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.55,
                child: ElevatedButton(
                  onPressed: widget.auth.loading ? null : widget.onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F75BC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: widget.auth.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit & Continue'),
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedFormField(
                animation: curvedAnimation,
                delay: 0.6,
                child: TextButton(
                  onPressed: widget.auth.loading
                      ? null
                      : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade700,
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

  /// Builds the header from the new image
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0F75BC).withOpacity(0.1),
          ),
          child: const Icon(
            Icons.group_work_outlined, // Changed icon
            color: Color(0xFF0F75BC),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Join the Dental Insights Network',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F2A5F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your profile to request peer reviews, collaborate on cases, and share expertise.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.blueGrey.shade600,
          ),
        ),
      ],
    );
  }

  /// Builds the section headers (e.g., "1. Account Details")
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: const Color(0xFF0F2A5F),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

//
// --- This widget creates the "Label above Field" design ---
//
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. The Label
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        // 2. The Text Field
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
            fillColor: const Color(0xFFF6F9FF),
            hintStyle: TextStyle(color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0F75BC),
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

//
// --- Animation Helper Widget ---
//
class _AnimatedFormField extends StatelessWidget {
  const _AnimatedFormField({
    required this.animation,
    required this.delay,
    required this.child,
  });

  final Animation<double> animation;
  final double delay; // 0.0 to 1.0
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
      begin: const Offset(0, 0.2), // Start 20% down
      end: Offset.zero,
    ).animate(intervalAnimation);

    return FadeTransition(
      opacity: intervalAnimation,
      child: SlideTransition(position: slideAnimation, child: child),
    );
  }
}

//
// --- Animated Background Widgets ---
//
class _AnimatedAura extends StatelessWidget {
  const _AnimatedAura({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
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
              child: const _AuraCircle(
                diameter: 280,
                colors: [Color(0x331A73E8), Color(0x33137BD1)],
              ),
            ),
            Positioned(
              bottom: -140,
              right: -80 + wave * 12,
              child: Text("hfd"),
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x1A0F75BC), Color(0x330F9DDA)],
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
  Widget build(BuildContext ctext) {
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
