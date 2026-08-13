import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

enum _AuthMode { signIn, signUp }

/// Shown whenever there's no signed-in Firebase user. Gates the rest of the
/// app (see AuthGate in main.dart) — nothing past this screen touches local
/// data until an account is signed in.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().contains('@') && _passwordController.text.length >= 6 && !_busy;

  Future<void> _submitEmail() async {
    setState(() => _busy = true);
    final auth = context.read<AppAuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_mode == _AuthMode.signIn) {
        await auth.signInWithEmail(_emailController.text, _passwordController.text);
      } else {
        await auth.signUpWithEmail(_emailController.text, _passwordController.text);
      }
      // On success, AuthGate rebuilds via authStateChanges — nothing else to do here.
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _busy = true);
    final auth = context.read<AppAuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.signInWithGoogle();
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (!email.contains('@')) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter your email above first.')));
      return;
    }
    try {
      await context.read<AppAuthProvider>().sendPasswordResetEmail(email);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSignIn = _mode == _AuthMode.signIn;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.fitness_center_rounded, size: 56, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  'Fitness Tracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  isSignIn ? 'Sign in to your account' : 'Create an account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
                const SizedBox(height: 32),
                _field(colors, 'Email', _emailController, obscure: false, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _field(
                  colors,
                  'Password',
                  _passwordController,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    color: colors.textSecondary,
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                if (isSignIn) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : _forgotPassword,
                      child: Text('Forgot password?', style: TextStyle(color: colors.primary, fontSize: 12.5)),
                    ),
                  ),
                ] else
                  const SizedBox(height: 8),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submitEmail : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colors.primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(isSignIn ? 'Sign In' : 'Create Account', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: colors.textSecondary.withValues(alpha: 0.25))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: colors.textSecondary.withValues(alpha: 0.25))),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _submitGoogle,
                    icon: Icon(Icons.g_mobiledata_rounded, color: colors.textPrimary, size: 26),
                    label: Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.textSecondary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _mode = isSignIn ? _AuthMode.signUp : _AuthMode.signIn),
                  child: Text.rich(
                    TextSpan(
                      text: isSignIn ? 'New here? ' : 'Already have an account? ',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      children: [
                        TextSpan(
                          text: isSignIn ? 'Create an account' : 'Sign in',
                          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    AppPalette colors,
    String hint,
    TextEditingController controller, {
    required bool obscure,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textSecondary),
        filled: true,
        fillColor: colors.surface,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}
