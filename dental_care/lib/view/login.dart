import 'dart:math' as math;
import 'package:dental_care/view/register.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF), // Example background
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: widget.floating,
      builder: (context, child) {
        final double wave = math.sin(widget.floating.value * 2 * math.pi) * 6;
        return Transform.translate(offset: Offset(0, wave), child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 28,
              offset: Offset(0, 22),
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
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F75BC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome back, Doctor',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0E3D7E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in to review cases and collaborate across your network.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: widget.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Professional email',
                    prefixIcon: const Icon(Icons.alternate_email_outlined),
                    filled: true,
                    fillColor: const Color(0xFFF5F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F75BC),
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
                    fillColor: const Color(0xFFF5F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F75BC),
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

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password recovery is coming soon.'),
                        ),
                      );
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign In Button
                ElevatedButton.icon(
                  onPressed: widget.auth.loading
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          if (!widget.formKey.currentState!.validate()) {
                            return;
                          }
                          try {
                            // Call the provider to log in
                            await widget.auth.login(
                              widget.email.text.trim(),
                              widget.password.text.trim(),
                            );

                            // Check login success *after* await
                            if (widget.auth.uid != null && mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/dashboard',
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            final msg = e is Exception
                                ? e.toString().replaceFirst('Exception: ', '')
                                : 'Login failed';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red.shade600,
                              ),
                            );
                          }
                        },
                  icon: widget.auth.loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      widget.auth.loading ? 'Signing you in...' : 'Sign in',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F75BC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                OutlinedButton(
                  onPressed: widget.auth.loading
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0F75BC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: const Color(0xFF0F75BC),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
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
        fillColor: const Color(0xFFF5F8FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF0F75BC), width: 1.6),
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
