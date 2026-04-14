import 'dart:async';
import 'package:flutter/material.dart';
import 'student_dashboard_screen.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';
import '../widgets/loaders/app_loader.dart';

class StudentLandingScreen extends StatefulWidget {
  const StudentLandingScreen({super.key});

  @override
  State<StudentLandingScreen> createState() => _StudentLandingScreenState();
}

class _StudentLandingScreenState extends State<StudentLandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        color: colorScheme.onPrimary,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Dental Student Learning Hub',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take assigned quizzes, track your progress, and improve with guided review.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/'),
                          child: const Text('Log In'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, '/register',
                              arguments: {'role': 'Student'}),
                          child: const Text('Sign Up as Student'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String email = (args?['email'] as String? ?? '').trim();
    final masked = email.contains('@')
        ? '${email.substring(0, 2)}***@${email.split('@').last}'
        : 'your email';

    return _EmailVerificationContent(maskedEmail: masked);
  }
}

class _EmailVerificationContent extends StatefulWidget {
  const _EmailVerificationContent({required this.maskedEmail});

  final String maskedEmail;

  @override
  State<_EmailVerificationContent> createState() =>
      _EmailVerificationContentState();
}

class _EmailVerificationContentState extends State<_EmailVerificationContent> {
  int _seconds = 0;
  Timer? _timer;
  String? _inlineMessage;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _seconds = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.resendEmailVerification();
      if (!mounted) return;
      _startCooldown();
      setState(() => _inlineMessage = 'Verification email sent.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _inlineMessage = 'Unable to resend verification email.');
    }
  }

  Future<void> _continue() async {
    final auth = context.read<AuthProvider>();
    final verified = await auth.refreshEmailVerificationStatus();
    if (!mounted) return;
    if (verified) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()));
      return;
    }
    setState(() =>
        _inlineMessage = 'Email not verified yet. Please check your inbox.');
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 54),
                const SizedBox(height: 16),
                Text(
                  'Verify your email',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'A verification email was sent to ${widget.maskedEmail}.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_inlineMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _inlineMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: loading || _seconds > 0 ? null : _resend,
                      child: Text(
                        _seconds > 0 ? 'Resend in ${_seconds}s' : 'Resend',
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: loading ? null : _continue,
                      child: loading
                          ? const AppLoader(size: 18)
                          : const Text('I have verified'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.pushReplacementNamed(context, '/'),
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordFlowScreen extends StatefulWidget {
  const ForgotPasswordFlowScreen({super.key});

  @override
  State<ForgotPasswordFlowScreen> createState() =>
      _ForgotPasswordFlowScreenState();
}

class _ForgotPasswordFlowScreenState extends State<ForgotPasswordFlowScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Forgot Password',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _submitted
                        ? 'If this email is registered, a password reset link has been sent.'
                        : 'Enter your account email and we will send a reset link.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Email is required';
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(email)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: auth.loading
                        ? null
                        : () async {
                            FocusScope.of(context).unfocus();
                            if (!_formKey.currentState!.validate()) return;
                            try {
                              await context
                                  .read<AuthProvider>()
                                  .sendPasswordResetEmail(
                                    _emailController.text.trim(),
                                  );
                              if (!mounted) return;
                              setState(() => _submitted = true);
                            } catch (_) {
                              if (!mounted) return;
                              setState(() => _submitted = true);
                            }
                          },
                    child: auth.loading
                        ? const AppLoader(size: 18)
                        : const Text('Send reset link'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: auth.loading
                        ? null
                        : () => Navigator.pushReplacementNamed(context, '/'),
                    child: const Text('Back to login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56),
            const SizedBox(height: 12),
            const Text('Unauthorized access'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('Go to login'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 56),
            const SizedBox(height: 12),
            const Text('Page not found'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                final isStudent = auth.userRole.toLowerCase() == 'student';
                if (isStudent) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StudentDashboardScreen()));
                } else {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                }
              },
              child: const Text('Go to dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
