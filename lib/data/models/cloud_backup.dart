class CloudBackup {
  const CloudBackup({
    required this.key,
    required this.revision,
    required this.payload,
    required this.updatedAt,
  });
  final String key;
  final int revision;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  String get name => (payload['profile'] as Map)['name'] as String;

  factory CloudBackup.fromJson(Map<String, dynamic> json) => CloudBackup(
    key: json['profile_key'] as String,
    revision: (json['revision'] as num).toInt(),
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

class BackupConflict implements Exception {
  const BackupConflict();
}
