import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_card.dart';
import '../widgets/auto_top_bar.dart';
import '../widgets/section_header.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _authService = AuthService();
  final _newEmailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const AutoTopBar(
        title: 'Account Security',
        subtitle: 'Secure links for email verification and password changes',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
        children: [
          SectionHeader(
            title: 'Signed-in Email',
            subtitle: user?.email ?? 'No email found',
          ),
          AutoCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (user?.emailVerified ?? false)
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    (user?.emailVerified ?? false)
                        ? Icons.verified_rounded
                        : Icons.mark_email_unread_rounded,
                    color: (user?.emailVerified ?? false)
                        ? AppTheme.success
                        : AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (user?.emailVerified ?? false)
                            ? 'Email verified'
                            : 'Email needs verification',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AutoSched AI uses secure email links instead of showing sensitive account actions directly in the app.',
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
          ),
          const SectionHeader(
            title: 'Secure Email Actions',
            subtitle:
                'These actions send a link to your inbox. This works like an OTP-style verification flow.',
          ),
          AutoCard(
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _sendVerification,
                    icon: const Icon(Icons.mark_email_read_rounded),
                    label: const Text('Send verification link'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _sendPasswordChange,
                    icon: const Icon(Icons.password_rounded),
                    label: const Text('Change password by email link'),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'Change Email',
            subtitle:
                'A confirmation link will be sent to the new email before it becomes active.',
          ),
          AutoCard(
            child: Column(
              children: [
                TextField(
                  controller: _newEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'New email address',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _sendEmailChange,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send email change link'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _sendVerification() async {
    await _runAction(
      () => _authService.sendEmailVerification(),
      'Verification link sent. Please check your inbox.',
    );
  }

  Future<void> _sendPasswordChange() async {
    await _runAction(
      () => _authService.sendPasswordChangeLink(),
      'Password change link sent. Please check your inbox.',
    );
  }

  Future<void> _sendEmailChange() async {
    final newEmail = _newEmailController.text.trim();
    if (!newEmail.contains('@')) {
      _show('Enter a valid new email address.', isError: true);
      return;
    }
    await _runAction(
      () => _authService.sendEmailChangeVerification(newEmail),
      'Email change confirmation sent to $newEmail.',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String success,
  ) async {
    setState(() => _loading = true);
    try {
      await action();
      _show(success);
    } catch (error) {
      _show(firebaseAuthErrorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppTheme.danger : null,
      ),
    );
  }
}
