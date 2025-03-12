import 'package:pocketbase/pocketbase.dart';

class Inspection {
  final String id;
  final String accessId;
  final String inspectorId;
  final String inspectorName;
  final DateTime timestamp;
  final Map<String, dynamic> checklist;
  final List<String> photos; // URLs (online) o paths (offline)
  final String photoType; // 'url' o 'path'
  final String signature; // URL (online) o path (offline)
  final String signatureType; // 'url' o 'path'
  final String status;
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
    required this.photoType,
    required this.signature,
    required this.signatureType,
    required this.status,
    this.notes,
    required this.isSync,
  });

  factory Inspection.fromRecord(RecordModel record) {
    final signatureList = record.getListValue<String>('signature');
    final photosList = record.getListValue<String>('photos');

    return Inspection(
      id: record.id,
      accessId: record.getStringValue('access'),
      inspectorId: record.getStringValue('inspector'),
      inspectorName: record.getStringValue('inspectorName'),
      timestamp: DateTime.parse(record.getStringValue('timestamp')),
      checklist: record.data['checklist'],
      photos: photosList,
      photoType: 'url',
      signature: signatureList.isNotEmpty ? signatureList.first : '',
      signatureType: 'url',
      status: record.getStringValue('status'),
      notes: record.getStringValue('notes'),
      isSync: record.getBoolValue('isSync'),
    );
  }

  factory Inspection.fromJson(Map<String, dynamic> json) {
    // Manejar tanto el formato online como offline
    List<String> photosList = [];
    String? photoType;

    if (json.containsKey('photos') && json['photos'] != null) {
      photosList = List<String>.from(json['photos']);
      photoType = 'url'; // Asumimos URLs por defecto
    }
    // Si tenemos photosPaths en lugar de photos (formato offline)
    else if (json.containsKey('photosPaths') && json['photosPaths'] != null) {
      photosList = List<String>.from(json['photosPaths']);
      photoType = 'path'; // Son paths de archivos locales
    }

    // Determinar la firma
    String? signatureValue = json['signature'];
    String? signatureType = 'url';

    // Si tenemos signaturePath en lugar de signature (formato offline)
    if (json.containsKey('signaturePath') && json['signaturePath'] != null) {
      signatureValue = json['signaturePath'];
      signatureType = 'path'; // Es path de archivo local
    }

    return Inspection(
      id: json['id'] ?? '',
      accessId: json['access'],
      inspectorId: json['inspector'],
      inspectorName: json['inspectorName'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp']),
      checklist: json['checklist'],
      photos: photosList,
      photoType: photoType ?? 'url',
      signature: signatureValue ?? '',
      signatureType: signatureType,
      status: json['status'],
      notes: json['notes'],
      isSync: json['isSync'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    // Formato estándar para almacenamiento
    final jsonData = {
      'id': id,
      'access': accessId,
      'inspector': inspectorId,
      'inspectorName': inspectorName,
      'timestamp': timestamp.toIso8601String(),
      'checklist': checklist,
      'status': status,
      'notes': notes,
      'isSync': isSync,
    };

    // Añadir fotos según su tipo
    if (photoType == 'path') {
      jsonData['photosPaths'] = photos;
    } else {
      jsonData['photos'] = photos;
    }

    // Añadir firma según su tipo
    if (signatureType == 'path') {
      jsonData['signaturePath'] = signature;
    } else {
      jsonData['signature'] = signature;
    }

    return jsonData;
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

  // Verificar si es una inspección offline
  bool get isOffline {
    return id.startsWith('offline_');
  }
}
