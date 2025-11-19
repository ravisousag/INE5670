class LogEntry {
  final int id;
  final String nfcUuid;
  final bool userExists;
  final int? userId;
  final String timestamp;

  LogEntry({
    required this.id,
    required this.nfcUuid,
    required this.userExists,
    required this.userId,
    required this.timestamp,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      nfcUuid: json['nfc_uuid'],
      userExists: json['user_exists'],
      userId: json['user_id'],
      timestamp: json['timestamp'],
    );
  }
}
