import '../utils/date_time_utils.dart';

class ExtractedClassEntry {
  const ExtractedClassEntry({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    required this.room,
    required this.units,
    this.instructor = '',
    this.confidence = 0.88,
    this.sourceLine = '',
    this.needsReview = false,
  });

  final String id;
  final String subjectCode;
  final String subjectName;
  final int weekday;
  final int startMinute;
  final int endMinute;
  final String room;
  final int units;
  final String instructor;
  final double confidence;
  final String sourceLine;
  final bool needsReview;

  String get dayLabel => AutoDate.weekdayLong(weekday);
  String get timeLabel => AutoDate.formatTimeRange(startMinute, endMinute);
  bool get hasValidTime => startMinute >= 0 && endMinute > startMinute;
  bool get hasValidDay => weekday >= 1 && weekday <= 7;
  bool get isReady => subjectCode.trim().isNotEmpty && subjectName.trim().isNotEmpty && hasValidDay && hasValidTime;

  ExtractedClassEntry copyWith({
    String? id,
    String? subjectCode,
    String? subjectName,
    int? weekday,
    int? startMinute,
    int? endMinute,
    String? room,
    int? units,
    String? instructor,
    double? confidence,
    String? sourceLine,
    bool? needsReview,
  }) {
    return ExtractedClassEntry(
      id: id ?? this.id,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      weekday: weekday ?? this.weekday,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      room: room ?? this.room,
      units: units ?? this.units,
      instructor: instructor ?? this.instructor,
      confidence: confidence ?? this.confidence,
      sourceLine: sourceLine ?? this.sourceLine,
      needsReview: needsReview ?? this.needsReview,
    );
  }
}

class CorImportIssue {
  const CorImportIssue({
    required this.entryId,
    required this.message,
    this.isBlocking = false,
  });

  final String entryId;
  final String message;
  final bool isBlocking;
}
