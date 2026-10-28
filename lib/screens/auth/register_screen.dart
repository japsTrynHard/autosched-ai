import 'package:flutter/material.dart';

import '../../branding/auto_sched_brand_assets.dart';
import '../../models/user_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _schoolController = TextEditingController();
  final _courseController = TextEditingController();
  String _yearLevel = '1st Year';
  String _academicYear = '2025 - 2026';
  String _term = '1st Term';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _schoolController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFF0891B2)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Image.memory(AutoSchedBrandAssets.fullLogoBytes, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start smart scheduling',
                            style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create your account, verify your email, then import your COR schedule.',
                            style: TextStyle(color: Colors.white70, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Student information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'First name and last name are separated for proper school records.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (value) => value == null || value.trim().length < 2
                          ? 'Enter first name'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Last name',
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                      validator: (value) => value == null || value.trim().length < 2
                          ? 'Enter last name'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Enter your email';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  ),
                ),
                validator: (value) => value == null || value.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.verified_user_rounded),
                ),
                validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 22),
              Text(
                'Academic setup',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _schoolController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'School',
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _courseController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Course / strand',
                  prefixIcon: Icon(Icons.school_rounded),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _yearLevel,
                decoration: const InputDecoration(
                  labelText: 'Year level',
                  prefixIcon: Icon(Icons.layers_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
                  DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
                  DropdownMenuItem(value: '3rd Year', child: Text('3rd Year')),
                  DropdownMenuItem(value: '4th Year', child: Text('4th Year')),
                ],
                onChanged: (value) => setState(() => _yearLevel = value ?? _yearLevel),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _academicYear,
                      decoration: const InputDecoration(
                        labelText: 'School year',
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: '2025 - 2026', child: Text('2025 - 2026')),
                        DropdownMenuItem(value: '2026 - 2027', child: Text('2026 - 2027')),
                        DropdownMenuItem(value: '2027 - 2028', child: Text('2027 - 2028')),
                      ],
                      onChanged: (value) => setState(() => _academicYear = value ?? _academicYear),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _term,
                      decoration: const InputDecoration(
                        labelText: 'Term',
                        prefixIcon: Icon(Icons.event_note_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: '1st Term', child: Text('1st Term')),
                        DropdownMenuItem(value: '2nd Term', child: Text('2nd Term')),
                        DropdownMenuItem(value: '3rd Term', child: Text('3rd Term')),
                        DropdownMenuItem(value: 'Summer', child: Text('Summer')),
                      ],
                      onChanged: (value) => setState(() => _term = value ?? _term),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _register,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.person_add_alt_1_rounded),
                label: Text(_isLoading ? 'Creating account...' : 'Create Account'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName'.trim();

      final credential = await _authService.registerWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: fullName,
      );
      final user = credential.user;
      if (user != null) {
        final profile = UserProfileModel(
          userId: user.uid,
          firstName: firstName,
          lastName: lastName,
          fullName: fullName,
          school: _schoolController.text.trim().isEmpty
              ? 'National University Baliwag'
              : _schoolController.text.trim(),
          course: _courseController.text.trim().isEmpty
              ? 'BSIT - Mobile and Web Applications'
              : _courseController.text.trim(),
          yearLevel: _yearLevel,
          academicYear: _academicYear,
          term: _term,
          preferredStudyTime: 'Evening',
          sleepStartMinute: 22 * 60,
          sleepEndMinute: 6 * 60,
          wakeMinute: 6 * 60,
          maxStudyHoursPerDay: 3,
          breakMinutes: 10,
        );
        await _firestoreService.saveBootstrapProfile(profile, email: user.email);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _showMessage(firebaseAuthErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.danger,
      ),
    );
  }
}
