class Inspection {
  final String id;
  final String accessId;
  final String inspectorId;
  final String inspectorName;
  final DateTime timestamp;
  final Map<String, dynamic> checklist;
  final List<String> photos;
  final String signature;
  final String status; // 'pending', 'completed', 'flagged'
  final String? notes;
  final bool isSync;

  Inspection({
    required this.id,
    required this.accessId,
    required this.inspectorId,
    required this.inspectorName,
    required this.timestamp,
    required this.checklist,
    required this.photos,
    required this.signature,
    required this.status,
    this.notes,
    required this.isSync,
  });

  factory Inspection.fromRecord(dynamic record) {
    // Para registros PocketBase con relaciones expandidas
    String inspectorName = 'Unknown';

    if (record.expand != null && record.expand['inspector'] != null) {
      inspectorName = record.expand['inspector'].data['name'];
    }

    return Inspection(
      id: record.id,
      accessId: record.data['access'],
      inspectorId: record.data['inspector'],
      inspectorName: inspectorName,
      timestamp: DateTime.parse(record.data['timestamp']),
      checklist: record.data['checklist'],
      photos: List<String>.from(record.data['photos'] ?? []),
      signature: record.data['signature'],
      status: record.data['status'],
      notes: record.data['notes'],
      isSync: record.data['isSync'] ?? true,
    );
  }

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['id'] ?? '',
      accessId: json['access'],
      inspectorId: json['inspector'],
      inspectorName: json['inspectorName'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp']),
      checklist: json['checklist'],
      photos: List<String>.from(json['photos']),
      signature: json['signature'],
      status: json['status'],
      notes: json['notes'],
      isSync: json['isSync'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'access': accessId,
      'inspector': inspectorId,
      'inspectorName': inspectorName,
      'timestamp': timestamp.toIso8601String(),
      'checklist': checklist,
      'photos': photos,
      'signature': signature,
      'status': status,
      'notes': notes,
      'isSync': isSync,
    };
  }

  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  bool get hasIssues {
    // Verificar si algún elemento de la lista tiene estado 'Mal' o 'Revisar'
    return checklist.values.any((item) =>
        item is Map<String, dynamic> &&
        item['status'] != null &&
        (item['status'] == 'Mal' || item['status'] == 'Revisar'));
  }
}
