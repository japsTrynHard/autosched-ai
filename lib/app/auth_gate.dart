import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../branding/auto_sched_brand_assets.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auto_sched_shell.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'app_controller.dart';
import 'app_scope.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _verifiedOverrideUid;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StandaloneApp(home: _LoadingScreen(message: 'Checking your account...'));
        }
        if (user == null) {
          _verifiedOverrideUid = null;
          return const _StandaloneApp(home: LoginScreen());
        }
        final isVerified = user.emailVerified || _verifiedOverrideUid == user.uid;
        if (!isVerified) {
          return _StandaloneApp(
            home: EmailVerificationScreen(
              email: user.email ?? 'your email',
              onVerified: () => setState(() => _verifiedOverrideUid = user.uid),
            ),
          );
        }
        return _AppSession(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _AppSession extends StatefulWidget {
  const _AppSession({super.key, required this.user});

  final User user;

  @override
  State<_AppSession> createState() => _AppSessionState();
}

class _AppSessionState extends State<_AppSession> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final Future<AppController> _controllerFuture;
  AppController? _controller;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _firestoreService = FirestoreService();
    _controllerFuture = _loadController();
  }

  Future<AppController> _loadController() async {
    final bundle = await _firestoreService.loadOrSeedUserBundle(widget.user);
    final controller = AppController.firebase(
      bundle: bundle,
      firestoreService: _firestoreService,
      authService: _authService,
      email: widget.user.email,
    );
    _controller = controller;
    return controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StandaloneApp(home: _LoadingScreen(message: 'Loading your saved schedule...'));
        }
        if (snapshot.hasError) {
          return _StandaloneApp(
            home: _StartupErrorScreen(
              message: snapshot.error.toString(),
              onSignOut: _authService.signOut,
            ),
          );
        }

        final controller = snapshot.requireData;
        return AppScope(
          controller: controller,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'AutoSched AI',
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: controller.themeMode,
                home: const AutoSchedShell(),
              );
            },
          ),
        );
      },
    );
  }
}

class _StandaloneApp extends StatelessWidget {
  const _StandaloneApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AutoSched AI',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onVerified,
  });

  final String email;
  final VoidCallback onVerified;

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  bool _loading = false;
  bool _verified = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerification(silent: true));
    Future<void>.delayed(const Duration(milliseconds: 700), () => _checkVerification(silent: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerification(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = _verified ? 'Your email is verified' : 'Check your email';
    final subtitle = _verified
        ? 'Your account is ready. Continue to open your smart planner.'
        : 'We sent a secure verification link to ${widget.email}. Tap Verify Account in your email, then return here. This screen will update automatically.';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: colors.outlineVariant.withOpacity(0.65)),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(0.08),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: _verified
                    ? const Icon(Icons.verified_rounded, color: AppTheme.success, size: 54)
                    : Image.memory(AutoSchedBrandAssets.fullLogoBytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 24),
            if (!_verified) ...[
              _SecurityCard(
                icon: Icons.mark_email_read_rounded,
                title: 'Step 1',
                body: 'Open your email inbox or spam folder and look for the AutoSched AI verification message.',
              ),
              const SizedBox(height: 12),
              _SecurityCard(
                icon: Icons.touch_app_rounded,
                title: 'Step 2',
                body: 'Tap the Verify Account link in the email. After that, return to this app.',
              ),
              const SizedBox(height: 12),
              _SecurityCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Step 3',
                body: 'AutoSched AI checks your account automatically and unlocks your dashboard when verification is complete.',
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _loading ? null : _resendLink,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send verification link again'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _loading ? null : _authService.signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Use another account'),
              ),
              if (_loading) ...[
                const SizedBox(height: 18),
                const Center(child: CircularProgressIndicator()),
              ],
            ] else ...[
              _SecurityCard(
                icon: Icons.shield_rounded,
                title: 'Account protected',
                body: 'Your class schedules, tasks, planner history, and study preferences can now be saved safely to your account.',
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: widget.onVerified,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue to Home'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _checkVerification({required bool silent}) async {
    if (_verified || _loading) return;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      await _authService.reloadCurrentUser();
      final verified = _authService.currentUser?.emailVerified ?? false;
      if (!mounted) return;
      if (verified) {
        _timer?.cancel();
        setState(() {
          _verified = true;
          _loading = false;
        });
      } else if (!silent) {
        _showMessage('Email is not verified yet. Please tap the link in your inbox first.');
      }
    } catch (error) {
      if (!silent) _showMessage(firebaseAuthErrorMessage(error));
    } finally {
      if (mounted && !silent && !_verified) setState(() => _loading = false);
    }
  }

  Future<void> _resendLink() async {
    setState(() => _loading = true);
    try {
      await _authService.sendEmailVerification();
      _showMessage('Verification link sent again. Please check your inbox or spam folder.');
    } catch (error) {
      _showMessage(firebaseAuthErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.message, required this.onSignOut});

  final String message;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 58, color: AppTheme.danger),
              const SizedBox(height: 16),
              Text(
                'We could not load your account',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Use another account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
