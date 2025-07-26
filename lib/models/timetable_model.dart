class TimetableEntry {
  final String id;
  final String title; // e.g., "Maths Lecture"
  final String day; // e.g., "Monday"
  final String startTime; // e.g., "09:00 AM"
  final String endTime; // e.g., "10:00 AM"

  TimetableEntry({
    required this.id,
    required this.title,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory TimetableEntry.fromMap(String id, Map<String, dynamic> map) {
    return TimetableEntry(
      id: id,
      title: map['title'] ?? '',
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
