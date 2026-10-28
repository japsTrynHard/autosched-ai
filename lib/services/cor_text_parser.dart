import 'dart:convert';

import '../models/cor_extraction_model.dart';

/// Robust COR parser for NU-style Certificate of Registration text.
///
/// The important change here is that parsing is not dependent on a perfect
/// table row. It understands pasted PDF text, OCR text, and column-split lines
/// such as:
///
/// SUBJECT_CODE / DESCRIPTION / SECTION
/// DAY / TIME / ROOM
/// UNITS
class CorTextParser {
  static final RegExp _timeRangePattern = RegExp(
    r'\b([0O]?\d|1\d|2[0-3])\s*(?::|\.|;)\s*([0-5O]\d)\s*([AP])\.?\s*M?\.?\s*(?:-|–|—|to|TO)\s*([0O]?\d|1\d|2[0-3])\s*(?::|\.|;)\s*([0-5O]\d)\s*([AP])?\.?\s*M?\.?\b',
    caseSensitive: false,
  );

  static final RegExp _subjectAtStartPattern = RegExp(
    r'^\s*([A-Z][A-Z0-9]{4,14})\b(?:\s+|$)',
    caseSensitive: false,
  );

  static final RegExp _sectionPattern = RegExp(
    r'\b(?:ITE|IT|CS|CPE|BSCPE|BSCS|BSIT|BSBA|BSTM|BSHM|BSA|ABM|STEM|HUMSS|GAS|ICT)[- ]?\d{2,4}[A-Z]?\b',
    caseSensitive: false,
  );

  static final RegExp _dayPattern = RegExp(
    r'\b(MTWTHF|MTWTF|MTH|MWF|TTH|MONDAY|MON|TUESDAY|TUES|TUE|WEDNESDAY|WED|THURSDAY|THURS|THU|TH|FRIDAY|FRI|SATURDAY|SAT|SUNDAY|SUN|M|T|W|F|S)\b',
    caseSensitive: false,
  );

  /// Extracts class schedules from scanned or pasted COR text.
  static List<ExtractedClassEntry> parse(String rawText) {
    final normalized = _normalizedLines(rawText);
    if (normalized.isEmpty) return const [];

    final lines = _subjectTableOnly(normalized);
    if (lines.isEmpty) return const [];

    final entries = <ExtractedClassEntry>[];
    _SubjectContext? current;
    var pendingDays = <int>[];
    String? pendingRoom;
    var sequence = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upper = line.toUpperCase();
      if (_isHeaderOrNoise(upper)) continue;

      final startingCode = _startingSubjectCode(line);
      if (startingCode != null) {
        current = _subjectFromLine(line, startingCode, previous: current);
        pendingDays = _daysInLine(line);
        pendingRoom = null;

        final sameLineEntries = _entriesFromLine(
          line: line,
          subject: current,
          fallbackDays: pendingDays,
          fallbackRoom: pendingRoom,
          nearbyLines: _nearbyLines(lines, i),
          sequenceStart: sequence,
        );
        entries.addAll(sameLineEntries);
        sequence += sameLineEntries.length;
        continue;
      }

      if (current == null) continue;

      final standaloneUnits = _unitsFromStandaloneLine(line);
      if (standaloneUnits != null) {
        current = current.copyWith(units: standaloneUnits);
        _applyUnitsToSubject(entries, current.code, standaloneUnits);
        continue;
      }

      final detectedDays = _daysInLine(line);
      if (detectedDays.isNotEmpty && !_looksLikeSubjectNameLine(line)) {
        pendingDays = detectedDays;
      }

      final detectedRoom = _detectRoom(line);
      if (detectedRoom != null && detectedRoom != 'TBA') {
        pendingRoom = detectedRoom;
      }

      if (_canBeSubjectNameContinuation(line)) {
        current = current.withBetterName(_cleanSubjectName(line));
      }

      final lineEntries = _entriesFromLine(
        line: line,
        subject: current,
        fallbackDays: pendingDays,
        fallbackRoom: pendingRoom,
        nearbyLines: _nearbyLines(lines, i),
        sequenceStart: sequence,
      );
      entries.addAll(lineEntries);
      sequence += lineEntries.length;
    }

    return _dedupe(entries);
  }

  /// Converts AI JSON output into the same ExtractedClassEntry model.
  /// Accepted shape:
  /// {"classes":[{"subjectCode":"...","subjectName":"...","day":"TH","startTime":"05:00PM","endTime":"09:00PM","room":"304","units":3}]}
  static List<ExtractedClassEntry> parseAiJson(String content) {
    final jsonText = _extractJsonObject(content);
    if (jsonText == null) return const [];

    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) return const [];

    final classes = decoded['classes'];
    if (classes is! List) return const [];

    final entries = <ExtractedClassEntry>[];
    var sequence = 0;
    for (final item in classes) {
      if (item is! Map) continue;
      final map = item.map((key, value) => MapEntry('$key', value));

      final code = '${map['subjectCode'] ?? map['code'] ?? ''}'.trim().toUpperCase();
      final name = '${map['subjectName'] ?? map['description'] ?? map['name'] ?? ''}'.trim();
      final room = '${map['room'] ?? 'TBA'}'.trim().isEmpty ? 'TBA' : '${map['room']}'.trim().toUpperCase();
      final dayText = '${map['day'] ?? map['days'] ?? ''}'.trim();
      final startText = '${map['startTime'] ?? map['start'] ?? ''}'.trim();
      final endText = '${map['endTime'] ?? map['end'] ?? ''}'.trim();
      final units = _readUnits(map['units']) ?? 3;

      if (code.isEmpty || name.isEmpty || dayText.isEmpty || startText.isEmpty || endText.isEmpty) {
        continue;
      }

      final startMinute = _parseSingleTime(startText);
      final endMinute = _parseSingleTime(endText);
      if (startMinute == null || endMinute == null || endMinute <= startMinute) continue;

      final days = _expandDayText(dayText);
      for (final day in days) {
        entries.add(
          ExtractedClassEntry(
            id: 'ai_${DateTime.now().microsecondsSinceEpoch}_${sequence++}',
            subjectCode: code,
            subjectName: name,
            weekday: day,
            startMinute: startMinute,
            endMinute: endMinute,
            room: room,
            units: units,
            confidence: 0.94,
            sourceLine: 'AI extracted: $code $dayText $startText-$endText $room',
            needsReview: false,
          ),
        );
      }
    }

    return _dedupe(entries);
  }

  static List<String> _normalizedLines(String rawText) {
    var text = rawText;
    final replacements = <String, String>{
      '\r': '\n',
      '–': '-',
      '—': '-',
      '−': '-',
      '|': ' ',
      '¦': ' ',
      '•': ' ',
      '·': ' ',
      ' ': ' ',
      'A.M.': 'AM',
      'P.M.': 'PM',
      'a.m.': 'AM',
      'p.m.': 'PM',
      'A M': 'AM',
      'P M': 'PM',
      'a m': 'AM',
      'p m': 'PM',
    };
    replacements.forEach((bad, good) => text = text.replaceAll(bad, good));

    return text
        .split('\n')
        .map(_normalizeLine)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static String _normalizeLine(String line) {
    var value = line.trim();
    value = value.replaceAll('\t', ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ');
    value = value.replaceAll(RegExp(r'(?<=\d)\s*:\s*(?=\d)'), ':');
    value = value.replaceAll(RegExp(r'(?<=[APap])\s+M\b'), 'M');
    value = value.replaceAllMapped(RegExp(r'\b([APap])\.\s*M\.?\b'), (m) => '${m.group(1)!.toUpperCase()}M');
    value = value.replaceAll(RegExp(r'(?<=\d)[Oo](?=\d)'), '0');
    return value.trim();
  }

  static List<String> _subjectTableOnly(List<String> lines) {
    var start = 0;
    var foundHeader = false;

    for (var i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase();
      final joinedWithNext = lines.skip(i).take(3).join(' ').toUpperCase();
      if (upper.contains('SUBJECT CODE') ||
          (upper.contains('DESCRIPTION') && upper.contains('SCHEDULE')) ||
          (joinedWithNext.contains('SUBJECT CODE') && joinedWithNext.contains('DESCRIPTION'))) {
        start = i + 1;
        foundHeader = true;
        break;
      }
    }

    if (!foundHeader) {
      for (var i = 0; i < lines.length; i++) {
        if (_startingSubjectCode(lines[i]) != null) {
          start = i;
          break;
        }
      }
    }

    var end = lines.length;
    for (var i = start; i < lines.length; i++) {
      final upper = lines[i].toUpperCase();
      if (upper.startsWith('TOTAL UNITS') ||
          upper.startsWith('TOTAL AMOUNT') ||
          upper.startsWith('TUITION FEE') ||
          upper.startsWith('ASSESSMENT') ||
          upper.startsWith('MISCELLANEOUS FEES') ||
          upper.startsWith('OPTION 1') ||
          upper.startsWith('NOTES:') ||
          upper.startsWith('REGISTRAR') ||
          upper.startsWith('INSTALLMENT PLAN')) {
        end = i;
        break;
      }
    }

    return start >= end ? const [] : lines.sublist(start, end);
  }

  static bool _isHeaderOrNoise(String upper) {
    final compact = upper.replaceAll(RegExp(r'\s+'), ' ').trim();
    const exactHeaders = {
      'SUBJECT',
      'CODE',
      'SUBJECT CODE',
      'DESCRIPTION',
      'SECTION',
      'DAY',
      'DAYS',
      'SCHEDULE',
      'TIME',
      'ROOM',
      'UNITS',
      'LAB',
      'LEC',
    };
    if (exactHeaders.contains(compact)) return true;
    if (compact.contains('SUBJECT CODE') ||
        compact == 'DAY SCHEDULE ROOM' ||
        compact == 'SCHEDULE ROOM UNITS' ||
        compact == 'DAY SCHEDULE ROOM UNITS') {
      return true;
    }
    if (compact.contains('CERTIFICATE OF REGISTRATION')) return true;
    if (compact.startsWith('STUDENT ID')) return true;
    if (compact.startsWith('NAME:')) return true;
    if (compact.startsWith('CITIZENSHIP')) return true;
    if (compact.startsWith('SCHOOL YEAR')) return true;
    if (compact.startsWith('TERM:')) return true;
    if (compact.startsWith('COURSE:')) return true;
    if (compact.startsWith('FEE SCHEDULE')) return true;
    if (compact.startsWith('PAYMENT')) return true;
    return false;
  }

  static String? _startingSubjectCode(String line) {
    final match = _subjectAtStartPattern.firstMatch(line);
    if (match == null) return null;
    final token = match.group(1)!.toUpperCase();
    return _looksLikeSubjectCode(token) ? token : null;
  }

  static bool _looksLikeSubjectCode(String token) {
    if (token.length < 5 || token.length > 14) return false;
    if (!RegExp(r'^[A-Z][A-Z0-9]+$').hasMatch(token)) return false;

    const blocked = {
      'SUBJECT',
      'DESCRIPTION',
      'SECTION',
      'SCHEDULE',
      'STUDENT',
      'SCHOOL',
      'CITIZENSHIP',
      'CERTIFICATE',
      'REGISTRATION',
      'TUITION',
      'MISCELLANEOUS',
      'INSTALLMENT',
      'PAYMENT',
      'REGISTRAR',
      'BALANCE',
      'PHILIPPINES',
      'FILIPINO',
      'ADVANCED',
      'INFORMATION',
      'ASSURANCE',
      'SECURITY',
      'CAPSTONE',
      'PROJECT',
      'ELECTIVE',
      'SYSTEMS',
      'ADMINISTRATION',
      'MAINTENANCE',
      'ENTREPRENEURIAL',
    };
    if (blocked.contains(token)) return false;
    if (_isSectionOnly(token)) return false;

    final hasDigit = RegExp(r'\d').hasMatch(token);
    final knownPrefix = RegExp(r'^(CT|IT|CS|CC|GE|NSTP|PE|MATH|ENG|FIL|RIZ|ETH|STS|PURP|ART|MMW|CAP|THS|ENT|SYS|APP)').hasMatch(token);
    final hasCodeShape = RegExp(r'[A-Z]{2,}\d|\d[A-Z]').hasMatch(token);
    final nuNoDigitLabCode = token.startsWith('CT') && token.endsWith('L') && token.length >= 7;
    return hasDigit || knownPrefix || hasCodeShape || nuNoDigitLabCode;
  }

  static _SubjectContext _subjectFromLine(String line, String code, {_SubjectContext? previous}) {
    var remainder = line.replaceFirst(RegExp('^\\s*$code\\b', caseSensitive: false), ' ').trim();
    remainder = remainder.replaceAll(RegExp(r'\s+'), ' ');

    final timeMatch = _timeRangePattern.firstMatch(remainder);
    final sectionMatch = _sectionPattern.firstMatch(remainder);
    final dayIndex = _firstDayIndex(remainder);

    var nameEnd = remainder.length;
    for (final index in [sectionMatch?.start, timeMatch?.start, dayIndex]) {
      if (index != null && index >= 0 && index < nameEnd) nameEnd = index;
    }

    var name = nameEnd <= 0 ? '' : remainder.substring(0, nameEnd).trim();
    name = _cleanSubjectName(name);
    if (name.isEmpty && previous?.code.toUpperCase() == code.toUpperCase()) {
      name = previous!.name;
    }
    if (name.isEmpty) name = 'Subject name needs review';

    final units = _detectUnits(line) ?? previous?.units ?? 3;
    final instructor = _detectInstructor(line);

    return _SubjectContext(
      code: code,
      name: name,
      units: units,
      instructor: instructor,
    );
  }

  static List<ExtractedClassEntry> _entriesFromLine({
    required String line,
    required _SubjectContext subject,
    required List<int> fallbackDays,
    required String? fallbackRoom,
    required List<String> nearbyLines,
    required int sequenceStart,
  }) {
    final matches = _timeRangePattern.allMatches(line).toList();
    if (matches.isEmpty) return const [];

    final entries = <ExtractedClassEntry>[];
    for (var matchIndex = 0; matchIndex < matches.length; matchIndex++) {
      final match = matches[matchIndex];
      final previousEnd = matchIndex == 0 ? 0 : matches[matchIndex - 1].end;
      final nextStart = matchIndex + 1 < matches.length ? matches[matchIndex + 1].start : line.length;

      final segmentBefore = line.substring(previousEnd, match.start);
      final segmentAfter = line.substring(match.end, nextStart);

      var days = _daysInLine(segmentBefore);
      if (days.isEmpty) days = _daysInLine(line.substring(0, match.start));
      if (days.isEmpty) days = fallbackDays;
      if (days.isEmpty) days = _daysFromNearbyLines(nearbyLines);
      if (days.isEmpty) continue;

      final startMinute = _toMinute(match.group(1), match.group(2), match.group(3));
      var endMinute = _toMinute(match.group(4), match.group(5), match.group(6) ?? match.group(3));
      if (endMinute <= startMinute) endMinute = startMinute + 90;

      final room = _detectRoom(segmentAfter) ??
          _roomFromNearbyLines(nearbyLines, ignoreSectionOnly: true) ??
          fallbackRoom ??
          'TBA';

      final units = _detectUnits(line) ?? subject.units;
      final instructor = _detectInstructor(line).isEmpty ? subject.instructor : _detectInstructor(line);
      final needsReview = subject.name.toLowerCase().contains('review') ||
          room == 'TBA' ||
          startMinute < 0 ||
          endMinute <= startMinute;

      var localIndex = entries.length;
      for (final day in days.toSet()) {
        entries.add(
          ExtractedClassEntry(
            id: 'cor_${DateTime.now().microsecondsSinceEpoch}_${sequenceStart + localIndex}',
            subjectCode: subject.code,
            subjectName: subject.name,
            weekday: day,
            startMinute: startMinute,
            endMinute: endMinute,
            room: room,
            units: units,
            instructor: instructor,
            confidence: needsReview ? 0.82 : 0.98,
            sourceLine: line,
            needsReview: needsReview,
          ),
        );
        localIndex++;
      }
    }

    return entries;
  }

  static int? _firstDayIndex(String line) => _dayPattern.firstMatch(line)?.start;

  static List<int> _daysInLine(String line) {
    final normalized = line
        .toUpperCase()
        .replaceAll(RegExp(r'[(),]'), ' ')
        .replaceAll('/', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return const [];

    final days = <int>[];
    for (final match in _dayPattern.allMatches(normalized)) {
      final token = match.group(0)?.trim().toUpperCase();
      if (token == null || token.isEmpty) continue;
      days.addAll(_expandDayToken(token));
    }
    return days.toSet().toList();
  }

  static List<int> _expandDayText(String text) {
    final direct = _daysInLine(text);
    if (direct.isNotEmpty) return direct;

    final compact = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (compact.isEmpty) return const [];
    return _expandDayToken(compact);
  }

  static List<int> _expandDayToken(String token) {
    final value = token.toUpperCase().replaceAll(' ', '');
    switch (value) {
      case 'MONDAY':
      case 'MON':
      case 'M':
        return const [DateTime.monday];
      case 'TUESDAY':
      case 'TUES':
      case 'TUE':
      case 'T':
        return const [DateTime.tuesday];
      case 'WEDNESDAY':
      case 'WED':
      case 'W':
        return const [DateTime.wednesday];
      case 'THURSDAY':
      case 'THURS':
      case 'THU':
      case 'TH':
        return const [DateTime.thursday];
      case 'FRIDAY':
      case 'FRI':
      case 'F':
        return const [DateTime.friday];
      case 'SATURDAY':
      case 'SAT':
      case 'S':
        return const [DateTime.saturday];
      case 'SUNDAY':
      case 'SUN':
        return const [DateTime.sunday];
      case 'MTH':
        return const [DateTime.monday, DateTime.thursday];
      case 'MWF':
        return const [DateTime.monday, DateTime.wednesday, DateTime.friday];
      case 'TTH':
        return const [DateTime.tuesday, DateTime.thursday];
      case 'MTWTHF':
      case 'MTWTF':
        return const [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday];
      default:
        return const [];
    }
  }

  static int _toMinute(String? hourText, String? minuteText, String? meridiemText) {
    var hour = int.tryParse((hourText ?? '0').replaceAll(RegExp(r'[Oo]'), '0')) ?? 0;
    final minute = int.tryParse((minuteText ?? '0').replaceAll(RegExp(r'[Oo]'), '0')) ?? 0;
    final meridiem = (meridiemText ?? 'AM').toUpperCase();
    if (meridiem == 'PM' && hour != 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  static int? _parseSingleTime(String text) {
    final normalized = _normalizeLine(text);
    final match = RegExp(
      r'\b([0O]?\d|1\d|2[0-3])\s*(?::|\.|;)\s*([0-5O]\d)\s*([AP])\.?\s*M?\.?\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (match == null) return null;
    return _toMinute(match.group(1), match.group(2), match.group(3));
  }

  static int? _detectUnits(String line) {
    final unitsLabel = RegExp(r'\b(\d+(?:\.\d+)?)\s*(?:units?|unit)\b', caseSensitive: false).firstMatch(line);
    if (unitsLabel != null) return double.tryParse(unitsLabel.group(1) ?? '')?.round();

    final tokens = line.trim().split(' ');
    for (final token in tokens.reversed.take(3)) {
      final normalized = token.replaceAll(',', '').trim();
      final value = double.tryParse(normalized);
      if (value != null && value > 0 && value <= 12 && normalized.contains('.')) {
        return value.round();
      }
    }
    return null;
  }

  static int? _unitsFromStandaloneLine(String line) {
    final clean = line.trim();
    if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(clean)) return null;
    final value = double.tryParse(clean);
    if (value == null || value <= 0 || value > 12) return null;
    return value.round();
  }

  static int? _readUnits(Object? value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return double.tryParse(value.trim())?.round();
    return null;
  }

  static String? _detectRoom(String line) {
    var value = line.trim();
    if (value.isEmpty) return null;
    if (_isSectionOnly(value)) return null;

    final timeMatch = _timeRangePattern.firstMatch(value);
    if (timeMatch != null && timeMatch.end < value.length) {
      value = value.substring(timeMatch.end).trim();
    }

    value = value.replaceAll(_dayPattern, ' ');
    value = value.replaceAll(RegExp(r'\b\d+(?:\.\d+)?\s*units?\b', caseSensitive: false), ' ');
    value = value.replaceAll(RegExp(r'\b\d+\.0\b'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (value.isEmpty || _isSectionOnly(value)) return null;

    final roomMatch = RegExp(
      r'\b(?:ROOM\s*)?((?:[A-Z]{1,5}[- ]?)?\d{2,5}[A-Z]?(?:/[A-Z0-9]{1,6})?|LAB\s*[A-Z0-9-]*|COMLAB\s*\d*|GYM|ONLINE|TBA)\b',
      caseSensitive: false,
    ).firstMatch(value);
    if (roomMatch == null) return null;

    final room = roomMatch.group(1)?.trim() ?? roomMatch.group(0)?.trim() ?? 'TBA';
    final cleanRoom = room.replaceAll(RegExp(r'^ROOM\s*', caseSensitive: false), '').trim().toUpperCase();
    if (_isSectionOnly(cleanRoom)) return null;
    return cleanRoom;
  }

  static bool _isSectionOnly(String line) {
    final clean = line.trim();
    final match = _sectionPattern.firstMatch(clean);
    return match != null && match.start <= 1 && match.end >= clean.length - 1;
  }

  static bool _looksLikeSubjectNameLine(String line) {
    if (_timeRangePattern.hasMatch(line)) return false;
    if (_startingSubjectCode(line) != null) return false;
    if (_isSectionOnly(line)) return false;
    if (_detectRoom(line) != null && line.trim().split(' ').length <= 2) return false;
    return RegExp(r'[A-Za-z]{4,}').hasMatch(line);
  }

  static bool _canBeSubjectNameContinuation(String line) {
    final upper = line.toUpperCase();
    if (_isHeaderOrNoise(upper)) return false;
    if (_timeRangePattern.hasMatch(line)) return false;
    if (_startingSubjectCode(line) != null) return false;
    if (_unitsFromStandaloneLine(line) != null) return false;
    if (_isSectionOnly(line)) return false;
    if (_daysInLine(line).isNotEmpty && line.trim().split(' ').length <= 2) return false;
    if (_detectRoom(line) != null && line.trim().split(' ').length <= 2) return false;
    return RegExp(r'[A-Za-z]{4,}').hasMatch(line);
  }

  static String _detectInstructor(String line) {
    final match = RegExp(
      r'\b(Prof\.?|Professor|Mr\.?|Ms\.?|Mrs\.?)\s+[A-Z][a-zA-Z.\-]+(?:\s+[A-Z][a-zA-Z.\-]+){0,3}',
      caseSensitive: false,
    ).firstMatch(line);
    return match?.group(0)?.trim() ?? '';
  }

  static String _cleanSubjectName(String name) {
    var value = name.trim();
    value = value.replaceAll(_sectionPattern, ' ');
    value = value.replaceAll(_timeRangePattern, ' ');
    value = value.replaceAll(RegExp(r'\bROOM\s*\d+\b', caseSensitive: false), ' ');
    value = value.replaceAll(RegExp(r'\b\d+\.0\b'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();

    final replacements = <String, String>{
      'NFORMATION': 'INFORMATION',
      'INFORM ATION': 'INFORMATION',
      'ASSUR ANCE': 'ASSURANCE',
      'SECUR ITY': 'SECURITY',
      'PROJ ECT': 'PROJECT',
      'ELECT VE': 'ELECTIVE',
      'ADMINISTR ATION': 'ADMINISTRATION',
      'MAINTEN ANCE': 'MAINTENANCE',
      'ENTREPRENEUR IAL': 'ENTREPRENEURIAL',
      'TECHNO LOGY': 'TECHNOLOGY',
      'APPLIC ATION': 'APPLICATION',
      'DEVEL OPMENT': 'DEVELOPMENT',
    };
    replacements.forEach((bad, good) {
      value = value.replaceAll(RegExp(bad, caseSensitive: false), good);
    });
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static List<String> _nearbyLines(List<String> lines, int index) {
    final start = index - 3 < 0 ? 0 : index - 3;
    final end = index + 4 > lines.length ? lines.length : index + 4;
    return lines.sublist(start, end);
  }

  static List<int> _daysFromNearbyLines(List<String> lines) {
    for (final line in lines.reversed) {
      if (_timeRangePattern.hasMatch(line)) continue;
      if (_startingSubjectCode(line) != null) continue;
      if (_isSectionOnly(line)) continue;
      final days = _daysInLine(line);
      if (days.isNotEmpty) return days;
    }
    return const [];
  }

  static String? _roomFromNearbyLines(List<String> lines, {bool ignoreSectionOnly = true}) {
    for (final line in lines) {
      if (ignoreSectionOnly && _isSectionOnly(line)) continue;
      if (_startingSubjectCode(line) != null) continue;
      final room = _detectRoom(line);
      if (room != null && room != 'TBA') return room;
    }
    return null;
  }

  static void _applyUnitsToSubject(List<ExtractedClassEntry> entries, String code, int units) {
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.subjectCode.toUpperCase() == code.toUpperCase()) {
        entries[i] = entry.copyWith(units: units);
      }
    }
  }

  static List<ExtractedClassEntry> _dedupe(List<ExtractedClassEntry> entries) {
    final seen = <String>{};
    final clean = <ExtractedClassEntry>[];
    for (final entry in entries) {
      final key = '${entry.subjectCode.toUpperCase()}-${entry.weekday}-${entry.startMinute}-${entry.endMinute}-${entry.room.toUpperCase()}';
      if (seen.add(key)) clean.add(entry);
    }
    return clean;
  }

  static String? _extractJsonObject(String content) {
    var text = content.trim();
    text = text.replaceAll(RegExp(r'^```(?:json)?', multiLine: true), '').replaceAll('```', '').trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return text.substring(start, end + 1);
  }
}

class _SubjectContext {
  const _SubjectContext({
    required this.code,
    required this.name,
    required this.units,
    required this.instructor,
  });

  final String code;
  final String name;
  final int units;
  final String instructor;

  _SubjectContext copyWith({int? units}) {
    return _SubjectContext(
      code: code,
      name: name,
      units: units ?? this.units,
      instructor: instructor,
    );
  }

  _SubjectContext withBetterName(String nextName) {
    final clean = nextName.trim();
    if (clean.isEmpty) return this;
    if (!name.toLowerCase().contains('review') && name.length >= clean.length) return this;
    return _SubjectContext(
      code: code,
      name: clean,
      units: units,
      instructor: instructor,
    );
  }
}
