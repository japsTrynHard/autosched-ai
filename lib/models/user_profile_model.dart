class UserProfileModel {
  const UserProfileModel({
    required this.userId,
    required this.fullName,
    required this.school,
    required this.course,
    required this.yearLevel,
    required this.preferredStudyTime,
    required this.sleepStartMinute,
    required this.sleepEndMinute,
    required this.wakeMinute,
    required this.maxStudyHoursPerDay,
    required this.breakMinutes,
    this.firstName,
    this.lastName,
    this.academicYear = '2025 - 2026',
    this.term = '3rd Term',
    this.profileImagePath,
    this.profileImagePublicId,
    this.isWorkingStudent = false,
    this.hasExtracurricular = false,
  });

  factory UserProfileModel.fromFirestore(
    Map<String, dynamic> data, {
    required String fallbackUserId,
  }) {
    final fullName = _readString(data, 'fullName', 'AutoSched Student');
    final parsed = _splitName(fullName);

    return UserProfileModel(
      userId: _readString(data, 'userId', fallbackUserId),
      firstName: _readString(data, 'firstName', parsed.$1),
      lastName: _readString(data, 'lastName', parsed.$2),
      fullName: fullName,
      school: _readString(data, 'school', 'National University Baliwag'),
      course: _readString(data, 'course', 'BSIT - Mobile and Web Applications'),
      yearLevel: _readString(data, 'yearLevel', '3rd Year'),
      academicYear: _readString(data, 'academicYear', '2025 - 2026'),
      term: _readString(data, 'term', '3rd Term'),
      preferredStudyTime: _readString(data, 'preferredStudyTime', 'Evening'),
      sleepStartMinute: _readInt(data, 'sleepStartMinute', 22 * 60),
      sleepEndMinute: _readInt(data, 'sleepEndMinute', 6 * 60),
      wakeMinute: _readInt(data, 'wakeMinute', 6 * 60),
      maxStudyHoursPerDay: _readInt(data, 'maxStudyHoursPerDay', 3),
      breakMinutes: _readInt(data, 'breakMinutes', 10),
      profileImagePath: _nullableString(data['profileImageUrl']) ?? _nullableString(data['profileImagePath']),
      profileImagePublicId: _nullableString(data['profileImagePublicId']),
      isWorkingStudent: _readBool(data, 'isWorkingStudent', false),
      hasExtracurricular: _readBool(data, 'hasExtracurricular', false),
    );
  }

  final String userId;
  final String? firstName;
  final String? lastName;
  final String fullName;
  final String school;
  final String course;
  final String yearLevel;
  final String academicYear;
  final String term;
  final String preferredStudyTime;
  final int sleepStartMinute;
  final int sleepEndMinute;
  final int wakeMinute;
  final int maxStudyHoursPerDay;
  final int breakMinutes;
  final String? profileImagePath;
  final String? profileImagePublicId;
  final bool isWorkingStudent;
  final bool hasExtracurricular;

  String get displayFirstName {
    final value = firstName?.trim();
    if (value != null && value.isNotEmpty) return value;
    return _splitName(fullName).$1;
  }

  String get displayLastName {
    final value = lastName?.trim();
    if (value != null && value.isNotEmpty) return value;
    return _splitName(fullName).$2;
  }

  int get maxStudyMinutesPerDay => maxStudyHoursPerDay * 60;

  String get academicLabel => '$yearLevel • $academicYear • $term';

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'firstName': displayFirstName,
      'lastName': displayLastName,
      'fullName': fullName,
      'school': school,
      'course': course,
      'yearLevel': yearLevel,
      'academicYear': academicYear,
      'term': term,
      'preferredStudyTime': preferredStudyTime,
      'sleepStartMinute': sleepStartMinute,
      'sleepEndMinute': sleepEndMinute,
      'wakeMinute': wakeMinute,
      'maxStudyHoursPerDay': maxStudyHoursPerDay,
      'breakMinutes': breakMinutes,
      'profileImagePath': profileImagePath,
      'profileImageUrl': profileImagePath,
      'profileImagePublicId': profileImagePublicId,
      'isWorkingStudent': isWorkingStudent,
      'hasExtracurricular': hasExtracurricular,
    };
  }

  UserProfileModel copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? fullName,
    String? school,
    String? course,
    String? yearLevel,
    String? academicYear,
    String? term,
    String? preferredStudyTime,
    int? sleepStartMinute,
    int? sleepEndMinute,
    int? wakeMinute,
    int? maxStudyHoursPerDay,
    int? breakMinutes,
    String? profileImagePath,
    String? profileImagePublicId,
    bool clearProfileImagePath = false,
    bool? isWorkingStudent,
    bool? hasExtracurricular,
  }) {
    final nextFirst = firstName ?? this.firstName;
    final nextLast = lastName ?? this.lastName;
    final nextFull = fullName ?? _composeName(nextFirst, nextLast, this.fullName);

    return UserProfileModel(
      userId: userId ?? this.userId,
      firstName: nextFirst,
      lastName: nextLast,
      fullName: nextFull,
      school: school ?? this.school,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      academicYear: academicYear ?? this.academicYear,
      term: term ?? this.term,
      preferredStudyTime: preferredStudyTime ?? this.preferredStudyTime,
      sleepStartMinute: sleepStartMinute ?? this.sleepStartMinute,
      sleepEndMinute: sleepEndMinute ?? this.sleepEndMinute,
      wakeMinute: wakeMinute ?? this.wakeMinute,
      maxStudyHoursPerDay: maxStudyHoursPerDay ?? this.maxStudyHoursPerDay,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      profileImagePath: clearProfileImagePath
          ? null
          : profileImagePath ?? this.profileImagePath,
      profileImagePublicId: clearProfileImagePath
          ? null
          : profileImagePublicId ?? this.profileImagePublicId,
      isWorkingStudent: isWorkingStudent ?? this.isWorkingStudent,
      hasExtracurricular: hasExtracurricular ?? this.hasExtracurricular,
    );
  }
}

String _readString(Map<String, dynamic> data, String key, String fallback) {
  final value = data[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

int _readInt(Map<String, dynamic> data, String key, int fallback) {
  final value = data[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _readBool(Map<String, dynamic> data, String key, bool fallback) {
  final value = data[key];
  if (value is bool) return value;
  return fallback;
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

(String, String) _splitName(String fullName) {
  final cleaned = fullName.trim();
  if (cleaned.isEmpty) return ('AutoSched', 'Student');
  final parts = cleaned.split(RegExp(r'\s+'));
  if (parts.length == 1) return (parts.first, '');
  return (parts.first, parts.sublist(1).join(' '));
}

String _composeName(String? firstName, String? lastName, String fallback) {
  final first = firstName?.trim() ?? '';
  final last = lastName?.trim() ?? '';
  final joined = [first, last].where((part) => part.isNotEmpty).join(' ');
  return joined.isNotEmpty ? joined : fallback;
}
