import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_scope.dart';
import '../config/cloudinary_config.dart';
import '../models/user_profile_model.dart';
import '../services/cloudinary_profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_time_utils.dart';
import '../widgets/auto_card.dart';
import '../widgets/auto_top_bar.dart';
import '../widgets/brand_logo.dart';
import '../widgets/section_header.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryProfileService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _schoolController;
  late final TextEditingController _courseController;
  late final TextEditingController _academicYearController;

  late String _yearLevel;
  late String _term;
  late String _preferredTime;
  late int _wakeMinute;
  late int _sleepMinute;
  late int _maxStudyHours;
  late int _breakMinutes;
  late bool _workingStudent;
  late bool _hasExtracurricular;

  bool _initialized = false;
  bool _isSaving = false;
  String? _profileImageUrl;
  String? _profileImagePublicId;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _schoolController = TextEditingController();
    _courseController = TextEditingController();
    _academicYearController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = AppScope.of(context).profile;
    _firstNameController.text = profile.displayFirstName;
    _lastNameController.text = profile.displayLastName;
    _schoolController.text = profile.school;
    _courseController.text = profile.course;
    _academicYearController.text = profile.academicYear;
    _yearLevel = profile.yearLevel;
    _term = profile.term;
    _preferredTime = profile.preferredStudyTime;
    _wakeMinute = profile.wakeMinute;
    _sleepMinute = profile.sleepStartMinute;
    _maxStudyHours = profile.maxStudyHoursPerDay;
    _breakMinutes = profile.breakMinutes;
    _workingStudent = profile.isWorkingStudent;
    _hasExtracurricular = profile.hasExtracurricular;
    _profileImageUrl = profile.profileImagePath;
    _profileImagePublicId = profile.profileImagePublicId;
    _initialized = true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _schoolController.dispose();
    _courseController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasPhoto = _profileImageUrl != null || _selectedPhotoBytes != null;

    return Scaffold(
      appBar: const AutoTopBar(
        title: 'Edit Profile',
        subtitle: 'Update your photo, school term, and study preferences',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          children: [
            AutoCard(
              child: Row(
                children: [
                  _ProfilePhoto(
                    imageUrl: _profileImageUrl,
                    previewBytes: _selectedPhotoBytes,
                    name: '${_firstNameController.text} ${_lastNameController.text}'.trim(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile photo',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CloudinaryConfig.isConfigured
                              ? 'Take or upload a photo. It will be saved online so your profile picture stays after logout or app reinstall.'
                              : 'Photo backup needs Cloudinary setup before the selected image can be saved online.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isSaving ? null : _openPhotoOptions,
                              icon: const Icon(Icons.add_a_photo_rounded),
                              label: const Text('Change photo'),
                            ),
                            TextButton.icon(
                              onPressed: !hasPhoto || _isSaving
                                  ? null
                                  : () => setState(() {
                                        _profileImageUrl = null;
                                        _profileImagePublicId = null;
                                        _selectedPhotoBytes = null;
                                        _selectedPhotoName = null;
                                      }),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(
              title: 'Student Information',
              subtitle: 'This is shown in the dashboard and used for schedule planning.',
            ),
            AutoCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: (value) => value == null || value.trim().length < 2 ? 'Enter first name' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                            prefixIcon: Icon(Icons.badge_rounded),
                          ),
                          validator: (value) => value == null || value.trim().length < 2 ? 'Enter last name' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _schoolController,
                    decoration: const InputDecoration(
                      labelText: 'School',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _courseController,
                    decoration: const InputDecoration(
                      labelText: 'Course / strand',
                      prefixIcon: Icon(Icons.school_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(
              title: 'School Year and Term',
              subtitle: 'When a new term starts, old subjects stay in history and the planner uses the current term only.',
            ),
            AutoCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _academicYearController,
                    decoration: const InputDecoration(
                      labelText: 'School year',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                      hintText: '2025 - 2026',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter school year' : null,
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
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
                ],
              ),
            ),
            const SectionHeader(
              title: 'Study Preferences',
              subtitle: 'AutoSched AI uses these settings to avoid bad schedules.',
            ),
            AutoCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _preferredTime,
                    decoration: const InputDecoration(
                      labelText: 'Preferred study time',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Morning', child: Text('Morning')),
                      DropdownMenuItem(value: 'Afternoon', child: Text('Afternoon')),
                      DropdownMenuItem(value: 'Evening', child: Text('Evening')),
                      DropdownMenuItem(value: 'Flexible', child: Text('Flexible')),
                    ],
                    onChanged: (value) => setState(() => _preferredTime = value ?? _preferredTime),
                  ),
                  const SizedBox(height: 14),
                  _NumberStepper(
                    label: 'Max study hours per day',
                    value: _maxStudyHours,
                    min: 1,
                    max: 8,
                    suffix: 'h',
                    onChanged: (value) => setState(() => _maxStudyHours = value),
                  ),
                  const SizedBox(height: 12),
                  _NumberStepper(
                    label: 'Break buffer',
                    value: _breakMinutes,
                    min: 5,
                    max: 30,
                    step: 5,
                    suffix: 'm',
                    onChanged: (value) => setState(() => _breakMinutes = value),
                  ),
                  const SizedBox(height: 12),
                  _TimeRow(
                    label: 'Wake-up time',
                    minute: _wakeMinute,
                    onTap: () => _pickTime(isWake: true),
                  ),
                  const SizedBox(height: 10),
                  _TimeRow(
                    label: 'Sleep time',
                    minute: _sleepMinute,
                    onTap: () => _pickTime(isWake: false),
                  ),
                  const Divider(height: 28),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _workingStudent,
                    onChanged: (value) => setState(() => _workingStudent = value),
                    title: const Text('Working student'),
                    subtitle: const Text('The planner will protect more recovery time.'),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _hasExtracurricular,
                    onChanged: (value) => setState(() => _hasExtracurricular = value),
                    title: const Text('Has extracurricular activities'),
                    subtitle: const Text('The planner avoids overloading free time.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const _SavingProfileIcon()
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Securing Profile...' : 'Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPhotoOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile photo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how you want to update your account photo.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: const Text('Take photo'),
                  subtitle: const Text('Open camera and capture a new profile picture.'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Upload photo'),
                  subtitle: const Text('Choose an existing image from your gallery.'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null) return;
    await _pickProfilePhoto(source);
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 72,
      maxWidth: 720,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _selectedPhotoBytes = bytes;
      _selectedPhotoName = picked.name;
    });
  }

  Future<void> _pickTime({required bool isWake}) async {
    final current = isWake ? _wakeMinute : _sleepMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    setState(() {
      final minute = picked.hour * 60 + picked.minute;
      if (isWake) {
        _wakeMinute = minute;
      } else {
        _sleepMinute = minute;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final app = AppScope.of(context);
    final current = app.profile;

    setState(() => _isSaving = true);
    try {
      var imageUrl = _profileImageUrl;
      var imagePublicId = _profileImagePublicId;

      if (_selectedPhotoBytes != null) {
        final upload = await _cloudinary.uploadProfilePhoto(
          bytes: _selectedPhotoBytes!,
          fileName: _selectedPhotoName ?? 'profile_${current.userId}.jpg',
          userId: current.userId,
        );
        imageUrl = upload.secureUrl;
        imagePublicId = upload.publicId;
      }

      final next = UserProfileModel(
        userId: current.userId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
        school: _schoolController.text.trim().isEmpty ? current.school : _schoolController.text.trim(),
        course: _courseController.text.trim().isEmpty ? current.course : _courseController.text.trim(),
        yearLevel: _yearLevel,
        academicYear: _academicYearController.text.trim(),
        term: _term,
        preferredStudyTime: _preferredTime,
        sleepStartMinute: _sleepMinute,
        sleepEndMinute: current.sleepEndMinute,
        wakeMinute: _wakeMinute,
        maxStudyHoursPerDay: _maxStudyHours,
        breakMinutes: _breakMinutes,
        profileImagePath: imageUrl,
        profileImagePublicId: imagePublicId,
        isWorkingStudent: _workingStudent,
        hasExtracurricular: _hasExtracurricular,
      );

      app.updateProfile(next);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}


class _SavingProfileIcon extends StatelessWidget {
  const _SavingProfileIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.3,
              color: Colors.white,
            ),
          ),
          AutoSchedMark(size: 14, borderRadius: 5, showBorder: false),
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({
    required this.imageUrl,
    required this.previewBytes,
    required this.name,
  });

  final String? imageUrl;
  final Uint8List? previewBytes;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget child;

    if (previewBytes != null) {
      child = ClipOval(child: Image.memory(previewBytes!, width: 72, height: 72, fit: BoxFit.cover));
    } else if (imageUrl != null && imageUrl!.startsWith('http')) {
      child = ClipOval(
        child: Image.network(
          imageUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialAvatar(name: name),
        ),
      );
    } else if (imageUrl != null && imageUrl!.startsWith('data:image')) {
      final bytes = base64Decode(imageUrl!.split(',').last);
      child = ClipOval(child: Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover));
    } else {
      child = _InitialAvatar(name: name);
    }

    return CircleAvatar(
      radius: 38,
      backgroundColor: colors.primary.withOpacity(0.12),
      child: child,
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      name.trim().isEmpty ? 'A' : name.trim().substring(0, 1).toUpperCase(),
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: colors.primary),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.suffix = '',
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
        IconButton.outlined(
          onPressed: value <= min ? null : () => onChanged(value - step),
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 58,
          child: Center(
            child: Text('$value$suffix', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        IconButton.outlined(
          onPressed: value >= max ? null : () => onChanged(value + step),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.minute, required this.onTap});

  final String label;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
            Text(AutoDate.formatMinute(minute), style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            const Icon(Icons.edit_calendar_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
