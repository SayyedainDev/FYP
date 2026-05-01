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
import '../../providers/loading_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _introController;
  late final AnimationController _floatingController;
  late final Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOut));

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _floatingController.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          return Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ScaleTransition(
                      scale: _cardScale, // Using the animation
                      child: _LoginCard(
                        formKey: _formKey,
                        email: _email,
                        password: _password,
                        auth: auth,
                        floating: _floatingController, // Pass animation
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard({
    required this.formKey,
    required this.email,
    required this.password,
    required this.auth,
    required this.floating,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final AuthProvider auth;
  final Animation<double> floating;

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _selectedRole = 'Student';
  bool _isSubmitting = false;
  String? _emailInlineError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AnimatedBuilder(
      animation: widget.floating,
      builder: (context, child) {
        final double wave = math.sin(widget.floating.value * 2 * math.pi) * 6;
        return Transform.translate(offset: Offset(0, wave), child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.15),
              blurRadius: 28,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
          child: Form(
            key: widget.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Header
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.medical_services_outlined,
                          color: colorScheme.primary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to PalPath',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to access quizzes, cases, and your dental learning network.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: widget.email,
                  onChanged: (_) {
                    if (_emailInlineError != null) {
                      setState(() => _emailInlineError = null);
                    }
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: _selectedRole == 'Student'
                        ? 'Student email'
                        : 'Professional email',
                    errorText: _emailInlineError,
                    prefixIcon: const Icon(Icons.alternate_email_outlined),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Please enter your email';
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(text)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: widget.password,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) return 'Please enter your password';
                    if (text.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _RoleChip(
                          icon: Icons.school_outlined,
                          label: 'Student',
                          isSelected: _selectedRole == 'Student',
                          color: colorScheme.tertiary,
                          onTap: () =>
                              setState(() => _selectedRole = 'Student'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _RoleChip(
                          icon: Icons.medical_services_outlined,
                          label: 'Doctor/Dentist',
                          isSelected: _selectedRole == 'Dentist',
                          color: colorScheme.primary,
                          onTap: () =>
                              setState(() => _selectedRole = 'Dentist'),
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                    ),
                    Text(
                      'Remember me',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ForgotPasswordFlowScreen()));
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign In Button
                Consumer<LoadingProvider>(
                  builder: (context, loadingState, _) {
                    return ElevatedButton.icon(
                      onPressed: (_isSubmitting || loadingState.isLoading)
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();
                              if (!widget.formKey.currentState!.validate()) {
                                AppDialogs.showWarningDialog(
                                  context,
                                  title: 'Missing Fields',
                                  message:
                                      'Please fill in all required fields.',
                                  confirmLabel: 'OK',
                                  onConfirm: () {},
                                );
                                return;
                              }
                              try {
                                setState(() => _isSubmitting = true);
                                // Call the provider to log in
                                await widget.auth
                                    .login(
                                      widget.email.text.trim(),
                                      widget.password.text.trim(),
                                      rememberMe: _rememberMe,
                                      studentOnly: _selectedRole == 'Student',
                                    )
                                    .timeout(const Duration(seconds: 30));

                                // Check login success *after* await
                                if (widget.auth.uid != null && mounted) {
                                  Navigator.pushReplacementNamed(
                                      context, '/dashboard');
                                }
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
                                if (e.code == 'user-not-found') {
                                  setState(() {
                                    _emailInlineError =
                                        'No account found with this email';
                                  });
                                  return;
                                }
                                if (e.code == 'wrong-password' ||
                                    e.code == 'invalid-credential') {
                                  AppDialogs.showErrorDialog(
                                    context,
                                    message:
                                        'Incorrect email or password. Please try again.',
                                  );
                                  return;
                                }
                                if (e.code == 'too-many-requests') {
                                  AppDialogs.showErrorDialog(
                                    context,
                                    message:
                                        'Account temporarily locked. Try again in 15 minutes.',
                                  );
                                  return;
                                }
                                if (e.code == 'network-request-failed') {
                                  AppDialogs.showNoInternetDialog(context);
                                  return;
                                }
                                AppDialogs.showErrorDialog(
                                  context,
                                  message: e.message ?? 'Login failed',
                                );
                              } catch (e, stack) {
                                if (!mounted) return;
                                if (e
                                    .toString()
                                    .contains('teacher_account_detected')) {
                                  AppDialogs.showErrorDialog(
                                    context,
                                    message:
                                        'This is a teacher account. Please switch role to Doctor/Dentist.',
                                  );
                                  return;
                                }
                                if (e
                                    .toString()
                                    .contains('student_account_detected')) {
                                  AppDialogs.showErrorDialog(
                                    context,
                                    message:
                                        'This is a student account. Please switch role to Student.',
                                  );
                                  return;
                                }
                                // Check if it's a known auth exception message string
                                final errStr = e.toString();
                                if (errStr.contains('firebase_auth') ||
                                    errStr.contains('Exception:')) {
                                  final msg = e is Exception
                                      ? errStr.replaceFirst('Exception: ', '')
                                      : 'Login failed';
                                  AppDialogs.showErrorDialog(context,
                                      message: msg);
                                } else {
                                  GlobalErrorHandler.instance
                                      .handleError(e, stack);
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            },
                      icon: (_isSubmitting || loadingState.isLoading)
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary.withValues(alpha: 0.9),
                                ),
                              ),
                            )
                          : const Icon(Icons.login_rounded, size: 24),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          (_isSubmitting || loadingState.isLoading)
                              ? 'Signing you in...'
                              : 'Sign in',
                          style:
                              const TextStyle(fontSize: 18, letterSpacing: 0.5),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        disabledBackgroundColor:
                            colorScheme.primary.withValues(alpha: 0.7),
                        disabledForegroundColor:
                            colorScheme.onPrimary.withValues(alpha: 0.9),
                        minimumSize: const Size(
                            double.infinity, 56), // Thick, large button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        elevation: 2,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pushNamed(context, '/register',
                          arguments: {'role': _selectedRole}),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: colorScheme.primary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  child: Text(
                    _selectedRole == 'Student'
                        ? 'Sign up as Student'
                        : 'Sign up as Doctor/Dentist',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color:
              isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.onToggle,
    required this.obscureText,
  });
  final TextEditingController controller;
  final VoidCallback onToggle;
  final bool obscureText;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant _PasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
            widget.onToggle(); // Notify the parent
          },
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      validator: (value) {
        final text = value ?? '';
        if (text.isEmpty) return 'Please enter your password';
        if (text.length < 8) {
          return 'Use at least 8 characters';
        }
        return null;
      },
    );
  }
}
