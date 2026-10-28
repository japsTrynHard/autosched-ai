class TimeRange {
  const TimeRange(this.startMinute, this.endMinute);

  final int startMinute;
  final int endMinute;

  int get durationMinutes => endMinute - startMinute;

  bool overlaps(TimeRange other) {
    return startMinute < other.endMinute && endMinute > other.startMinute;
  }

  TimeRange clampToDay(int dayStart, int dayEnd) {
    final start = startMinute < dayStart ? dayStart : startMinute;
    final end = endMinute > dayEnd ? dayEnd : endMinute;
    return TimeRange(start, end);
  }
}
