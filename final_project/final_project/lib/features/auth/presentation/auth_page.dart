import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:car_buying_app/main.dart';
import '../providers/auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────────────
  final _formKey         = GlobalKey<FormState>();
  final _emailCtrl       = TextEditingController();
  final _passCtrl        = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────────
  bool    _isLogin        = true;
  bool    _loading        = false;
  bool    _obscurePass    = true;
  bool    _obscureConfirm = true;
  String? _error;

  // ── Animation ─────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() { _isLogin = !_isLogin; _error = null; });
    _animCtrl.forward(from: 0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final svc = ref.read(authServiceProvider);
      if (_isLogin) {
        await svc.signIn(_emailCtrl.text, _passCtrl.text);
      } else {
        await svc.register(_emailCtrl.text, _passCtrl.text);
      }
      // GoRouter's refreshListenable handles navigation automatically.
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyError(e.code));
    } catch (_) {
      if (mounted) setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _DecorativeBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 48),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 52),
                        _buildHeadline(),
                        const SizedBox(height: 36),
                        _buildForm(),
                        const SizedBox(height: 28),
                        _buildCTA(),
                        const SizedBox(height: 20),
                        _buildToggle(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────

  Widget _buildLogo() => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.gold,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.directions_car_rounded,
            color: Colors.black, size: 24),
      ),
      const SizedBox(width: 14),
      const Text('AutoVault',
          style: TextStyle(
              color: AppTheme.textHigh,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2)),
    ],
  );

  Widget _buildHeadline() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 280),
    child: Column(
      key: ValueKey(_isLogin),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLogin ? 'Welcome\nback.' : 'Create your\naccount.',
          style: const TextStyle(
              color: AppTheme.textHigh,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -1.5),
        ),
        const SizedBox(height: 10),
        Text(
          _isLogin
              ? 'Sign in to find your next car.'
              : 'Join AutoVault to start shopping.',
          style: const TextStyle(
              color: AppTheme.textMed, fontSize: 15, height: 1.5),
        ),
      ],
    ),
  );

  Widget _buildForm() => Form(
    key: _formKey,
    child: Column(
      children: [
        // Email
        _Field(
          controller: _emailCtrl,
          label: 'Email address',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@') || !v.contains('.')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Password
        _Field(
          controller: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePass,
          textInputAction:
          _isLogin ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: _isLogin ? (_) => _submit() : null,
          suffixIcon: _VisibilityToggle(
            obscure: _obscurePass,
            onTap: () => setState(() => _obscurePass = !_obscurePass),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Minimum 6 characters';
            return null;
          },
        ),

        // Confirm password (register only) — animated expand
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _isLogin
              ? const SizedBox.shrink()
              : Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _Field(
              controller: _confirmPassCtrl,
              label: 'Confirm password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: _VisibilityToggle(
                obscure: _obscureConfirm,
                onTap: () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) => v != _passCtrl.text
                  ? 'Passwords do not match'
                  : null,
            ),
          ),
        ),

        // Error banner — animated expand
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          child: _error == null
              ? const SizedBox.shrink()
              : Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _ErrorBanner(message: _error!),
          ),
        ),
      ],
    ),
  );

  Widget _buildCTA() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _loading ? null : _submit,
      child: _loading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor:
          AlwaysStoppedAnimation<Color>(Colors.black45),
        ),
      )
          : Text(_isLogin ? 'SIGN IN' : 'CREATE ACCOUNT'),
    ),
  );

  Widget _buildToggle() => Center(
    child: GestureDetector(
      onTap: _toggleMode,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          text: TextSpan(
            style:
            const TextStyle(fontSize: 14, color: AppTheme.textMed),
            children: [
              TextSpan(
                text: _isLogin
                    ? "Don't have an account?  "
                    : 'Already have an account?  ',
              ),
              TextSpan(
                text: _isLogin ? 'Sign Up' : 'Sign In',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// Reusable text field
// ─────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController       controller;
  final String                      label;
  final IconData                    icon;
  final bool                        obscureText;
  final TextInputType?              keyboardType;
  final TextInputAction?            textInputAction;
  final Widget?                     suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)?      onFieldSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:       controller,
    obscureText:      obscureText,
    keyboardType:     keyboardType,
    textInputAction:  textInputAction,
    onFieldSubmitted: onFieldSubmitted,
    validator:        validator,
    style: const TextStyle(color: AppTheme.textHigh, fontSize: 15),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Icon(icon, color: AppTheme.textMed, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(),
      suffixIcon: suffixIcon,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// Password visibility toggle icon button
// ─────────────────────────────────────────────────────────────────
class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscure, required this.onTap});
  final bool obscure;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(
      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      color: AppTheme.textMed,
      size: 20,
    ),
    onPressed: onTap,
  );
}

// ─────────────────────────────────────────────────────────────────
// Error message banner
// ─────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.red.withOpacity(0.35)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline_rounded,
              color: AppTheme.red, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  color: AppTheme.red, fontSize: 13, height: 1.45)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// Decorative background: gradient + radial gold glow orbs
// ─────────────────────────────────────────────────────────────────
class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF151008), Color(0xFF0D0D0D), Color(0xFF080808)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Top-right glow
        const Positioned(
          top: -110, right: -90,
          child: _Orb(size: 340, opacity: 0.13),
        ),
        // Bottom-left glow
        const Positioned(
          bottom: -90, left: -60,
          child: _Orb(size: 240, opacity: 0.07),
        ),
        // Thin horizontal shimmer line
        Positioned(
          top: MediaQuery.of(context).size.height * 0.60,
          left: 0, right: 0,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                AppTheme.gold.withOpacity(0.18),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.opacity});
  final double size, opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [
        AppTheme.gold.withOpacity(opacity),
        Colors.transparent,
      ]),
    ),
  );
}