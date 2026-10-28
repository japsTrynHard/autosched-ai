class ClassScheduleModel {
  const ClassScheduleModel({
    required this.id,
    required this.subjectId,
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    required this.room,
    this.source = 'Manual Entry',
    this.isFixed = true,
    this.academicYear = '2025 - 2026',
    this.term = '3rd Term',
    this.isArchived = false,
  });

  factory ClassScheduleModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ClassScheduleModel(
      id: id,
      subjectId: _readString(data, 'subjectId', ''),
      weekday: _readInt(data, 'weekday', 1),
      startMinute: _readInt(data, 'startMinute', 8 * 60),
      endMinute: _readInt(data, 'endMinute', 9 * 60),
      room: _readString(data, 'room', 'TBA'),
      source: _readString(data, 'source', 'Cloud Backup'),
      isFixed: _readBool(data, 'isFixed', true),
      academicYear: _readString(data, 'academicYear', '2025 - 2026'),
      term: _readString(data, 'term', '3rd Term'),
      isArchived: _readBool(data, 'isArchived', false),
    );
  }

  final String id;
  final String subjectId;
  final int weekday;
  final int startMinute;
  final int endMinute;
  final String room;
  final String source;
  final bool isFixed;
  final String academicYear;
  final String term;
  final bool isArchived;

  int get durationMinutes => endMinute - startMinute;
  String get termLabel => '$academicYear • $term';

  Map<String, dynamic> toFirestore() {
    return {
      'scheduleId': id,
      'subjectId': subjectId,
      'weekday': weekday,
      'startMinute': startMinute,
      'endMinute': endMinute,
      'room': room,
      'source': source,
      'isFixed': isFixed,
      'academicYear': academicYear,
      'term': term,
      'isArchived': isArchived,
    };
  }

  ClassScheduleModel copyWith({
    String? id,
    String? subjectId,
    int? weekday,
    int? startMinute,
    int? endMinute,
    String? room,
    String? source,
    bool? isFixed,
    String? academicYear,
    String? term,
    bool? isArchived,
  }) {
    return ClassScheduleModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      weekday: weekday ?? this.weekday,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      room: room ?? this.room,
      source: source ?? this.source,
      isFixed: isFixed ?? this.isFixed,
      academicYear: academicYear ?? this.academicYear,
      term: term ?? this.term,
      isArchived: isArchived ?? this.isArchived,
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
