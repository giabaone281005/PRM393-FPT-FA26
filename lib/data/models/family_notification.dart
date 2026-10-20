class FamilyNotification {
  const FamilyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id, title, body;
  final DateTime createdAt;
  final DateTime? readAt;

  factory FamilyNotification.fromMap(Map<String, dynamic> row) =>
      FamilyNotification(
        id: row['id'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        readAt: row['read_at'] == null
            ? null
            : DateTime.parse(row['read_at'] as String),
      );
}
