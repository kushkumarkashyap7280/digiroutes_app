import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../logic/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text.trim(),
        );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final textColor = AppTheme.textColor(context);
    final textSec = AppTheme.textSecColor(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: theme.brightness == Brightness.dark
                    ? AppTheme.darkBgGradient
                    : AppTheme.lightBgGradient,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),

                          // Logo & Heading
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.location_on_rounded,
                                    color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 12),
                              Text('DigiRoutes',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  )),
                            ],
                          ).animate().fadeIn().slideX(begin: -0.1, end: 0),

                          const SizedBox(height: 40),

                          Text('Welcome back',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -1,
                                  ))
                              .animate(delay: 100.ms)
                              .fadeIn()
                              .slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 6),

                          Text('Sign in to your account',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                color: textSec,
                              )).animate(delay: 150.ms).fadeIn(),

                          const SizedBox(height: 32),

                          // Error banner
                          if (auth.error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.danger.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppTheme.danger, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(auth.error!,
                                          style: GoogleFonts.outfit(
                                              color: AppTheme.danger,
                                              fontSize: 13))),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn()
                                .scale(begin: const Offset(0.95, 0.95)),

                          // Form card
                          GlassContainer(
                            radius: 22,
                            blur: 20,
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon:
                                        Icon(Icons.email_outlined, size: 20),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Email is required.';
                                    if (!v.contains('@'))
                                      return 'Enter a valid email.';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Password is required.';
                                    if (v.length < 6)
                                      return 'Minimum 6 characters.';
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                            ),
                          )
                              .animate(delay: 200.ms)
                              .fadeIn()
                              .slideY(begin: 0.08, end: 0),

                          const SizedBox(height: 24),

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _submit,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text('Sign In',
                                      style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ).animate(delay: 300.ms).fadeIn(),

                          const SizedBox(height: 20),

                          // Divider
                          Row(children: [
                            Expanded(child: Divider(color: theme.dividerColor)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or',
                                  style: GoogleFonts.outfit(
                                      color: AppTheme.mutedColor(context),
                                      fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: theme.dividerColor)),
                          ]).animate(delay: 350.ms).fadeIn(),

                          const SizedBox(height: 20),

                          // Sign up link
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go('/signup'),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.outfit(
                                      fontSize: 14, color: textSec),
                                  children: [
                                    const TextSpan(
                                        text: "Don't have an account? "),
                                    TextSpan(
                                      text: 'Sign up',
                                      style: GoogleFonts.outfit(
                                          color: AppTheme.orange,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate(delay: 400.ms).fadeIn(),
                        ],
                      ),
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
}
