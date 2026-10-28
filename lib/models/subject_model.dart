enum SubjectDifficulty { easy, moderate, hard, veryHard }

extension SubjectDifficultyX on SubjectDifficulty {
  String get label {
    switch (this) {
      case SubjectDifficulty.easy:
        return 'Easy';
      case SubjectDifficulty.moderate:
        return 'Moderate';
      case SubjectDifficulty.hard:
        return 'Hard';
      case SubjectDifficulty.veryHard:
        return 'Very Hard';
    }
  }

  int get score {
    switch (this) {
      case SubjectDifficulty.easy:
        return 1;
      case SubjectDifficulty.moderate:
        return 2;
      case SubjectDifficulty.hard:
        return 4;
      case SubjectDifficulty.veryHard:
        return 5;
    }
  }

  int get studyWeight {
    switch (this) {
      case SubjectDifficulty.easy:
        return 1;
      case SubjectDifficulty.moderate:
        return 2;
      case SubjectDifficulty.hard:
        return 3;
      case SubjectDifficulty.veryHard:
        return 4;
    }
  }
}

class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.units,
    required this.difficulty,
    this.instructor,
    this.academicYear = '2025 - 2026',
    this.term = '3rd Term',
    this.isArchived = false,
  });

  factory SubjectModel.fromFirestore(String id, Map<String, dynamic> data) {
    return SubjectModel(
      id: id,
      code: _readString(data, 'code', 'SUBJ'),
      name: _readString(data, 'name', 'Untitled Subject'),
      units: _readInt(data, 'units', 3),
      difficulty: _difficultyFromName(_readString(data, 'difficulty', 'moderate')),
      instructor: _nullableString(data['instructor']),
      academicYear: _readString(data, 'academicYear', '2025 - 2026'),
      term: _readString(data, 'term', '3rd Term'),
      isArchived: _readBool(data, 'isArchived', false),
    );
  }

  final String id;
  final String code;
  final String name;
  final int units;
  final SubjectDifficulty difficulty;
  final String? instructor;
  final String academicYear;
  final String term;
  final bool isArchived;

  String get displayName => '$code • $name';
  String get termLabel => '$academicYear • $term';

  Map<String, dynamic> toFirestore() {
    return {
      'subjectId': id,
      'code': code,
      'name': name,
      'units': units,
      'difficulty': difficulty.name,
      'difficultyLabel': difficulty.label,
      'difficultyWeight': difficulty.studyWeight,
      'instructor': instructor,
      'academicYear': academicYear,
      'term': term,
      'isArchived': isArchived,
    };
  }

  SubjectModel copyWith({
    String? id,
    String? code,
    String? name,
    int? units,
    SubjectDifficulty? difficulty,
    String? instructor,
    String? academicYear,
    String? term,
    bool? isArchived,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      units: units ?? this.units,
      difficulty: difficulty ?? this.difficulty,
      instructor: instructor ?? this.instructor,
      academicYear: academicYear ?? this.academicYear,
      term: term ?? this.term,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

SubjectDifficulty _difficultyFromName(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(' ', '');
  for (final item in SubjectDifficulty.values) {
    if (item.name.toLowerCase() == normalized ||
        item.label.toLowerCase().replaceAll(' ', '') == normalized) {
      return item;
    }
  }
  return SubjectDifficulty.moderate;
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
