class AdminAccess {
  const AdminAccess(this.role, this.status);
  final String role, status;
  bool get allowed => role == 'admin' && status == 'active';
}

class AdminAccount {
  const AdminAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
  });
  factory AdminAccount.fromJson(Map<String, dynamic> value) => AdminAccount(
    id: value['id'] as String,
    name: value['display_name'] as String,
    email: value['email'] as String? ?? '',
    status: value['status'] as String,
    createdAt: DateTime.parse(value['created_at'] as String),
  );
  final String id, name, email, status;
  final DateTime createdAt;
}

class AdminTopic {
  const AdminTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.subject,
    required this.status,
    required this.sortOrder,
    this.actionLabel = '',
    this.iconKey = 'menu_book_outlined',
    this.activityCount = 0,
  });
  factory AdminTopic.fromJson(Map<String, dynamic> value) => AdminTopic(
    id: value['id'] as String,
    title: value['title'] as String,
    subtitle: value['subtitle'] as String? ?? '',
    subject: value['subject'] as String,
    status: value['status'] as String,
    sortOrder: (value['sort_order'] as num).toInt(),
    actionLabel: value['action_label'] as String? ?? '',
    iconKey: value['icon_key'] as String,
    activityCount: (value['activity_count'] as num? ?? 0).toInt(),
  );
  final String id, title, subtitle, subject, status, actionLabel, iconKey;
  final int sortOrder, activityCount;
  Map<String, dynamic> toPayload() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'subject': subject,
    'status': status,
    'sort_order': sortOrder,
    'action_label': actionLabel,
    'icon_key': iconKey,
  };
}

class AdminRealtimeEvent {
  const AdminRealtimeEvent({required this.connected, this.changed = false});
  final bool connected, changed;
}
