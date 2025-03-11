class Alert {
  final String id;
  final String userId;
  final String userName;
  final String alertType;
  final DateTime timestamp;
  final Map<String, dynamic> geolocation;
  final String status;
  final String? resolvedById;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final String? notes;

  Alert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.alertType,
    required this.timestamp,
    required this.geolocation,
    required this.status,
    this.resolvedById,
    this.resolvedByName,
    this.resolvedAt,
    this.notes,
  });

  factory Alert.fromRecord(dynamic record) {
    String userName = 'Unknown';
    String? resolvedByName;

    if (record.expand != null && record.expand['user'] != null) {
      userName = record.expand['user'].data['name'];
    }

    if (record.expand != null && record.expand['resolvedBy'] != null) {
      resolvedByName = record.expand['resolvedBy'].data['name'];
    }

    return Alert(
      id: record.id,
      userId: record.data['user'],
      userName: userName,
      alertType: record.data['alertType'],
      timestamp: DateTime.parse(record.data['timestamp']),
      geolocation: record.data['geolocation'],
      status: record.data['status'],
      resolvedById: record.data['resolvedBy'],
      resolvedByName: resolvedByName,
      resolvedAt: record.data['resolvedAt'] != null
          ? DateTime.parse(record.data['resolvedAt'])
          : null,
      notes: record.data['notes'],
    );
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      userId: json['user'],
      userName: json['userName'] ?? 'Unknown',
      alertType: json['alertType'],
      timestamp: DateTime.parse(json['timestamp']),
      geolocation: json['geolocation'],
      status: json['status'],
      resolvedById: json['resolvedBy'],
      resolvedByName: json['resolvedByName'],
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'userName': userName,
      'alertType': alertType,
      'timestamp': timestamp.toIso8601String(),
      'geolocation': geolocation,
      'status': status,
      'resolvedBy': resolvedById,
      'resolvedByName': resolvedByName,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';
  bool get isFalseAlarm => status == 'false_alarm';
}
