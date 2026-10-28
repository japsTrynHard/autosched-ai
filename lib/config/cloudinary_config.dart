class CloudinaryConfig {
  const CloudinaryConfig._();

  /// Cloudinary cloud name and unsigned upload preset are not API secrets.
  /// The app ignores common placeholder dart-defines so running with
  /// CLOUDINARY_CLOUD_NAME=your_cloud_name will not break the demo upload.
  static const String _envCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String _envUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  static const String _envProfileFolder = String.fromEnvironment('CLOUDINARY_PROFILE_FOLDER');

  static String get cloudName => _cleanEnv(
        _envCloudName,
        fallback: 'dsehjla6',
        placeholders: const {'your_cloud_name', 'cloud_name', 'demo_cloud_name'},
      );

  static String get uploadPreset => _cleanEnv(
        _envUploadPreset,
        fallback: 'autosched_profile_unsigned',
        placeholders: const {'your_unsigned_upload_preset', 'upload_preset', 'preset_name'},
      );

  static String get profileFolder => _cleanEnv(
        _envProfileFolder,
        fallback: 'autosched_ai/profile_photos',
        placeholders: const {'folder', 'your_folder'},
      );

  static bool get isConfigured =>
      cloudName.trim().isNotEmpty &&
      uploadPreset.trim().isNotEmpty &&
      !_isPlaceholder(cloudName) &&
      !_isPlaceholder(uploadPreset);

  static String _cleanEnv(
    String value, {
    required String fallback,
    required Set<String> placeholders,
  }) {
    final clean = value.trim();
    if (clean.isEmpty) return fallback;
    if (placeholders.contains(clean.toLowerCase())) return fallback;
    if (_isPlaceholder(clean)) return fallback;
    return clean;
  }

  static bool _isPlaceholder(String value) {
    final clean = value.trim().toLowerCase();
    return clean.startsWith('your_') ||
        clean.contains('replace_me') ||
        clean.contains('example') ||
        clean == 'null' ||
        clean == 'undefined';
  }
}
