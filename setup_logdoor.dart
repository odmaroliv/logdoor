import 'dart:io';

void main() async {
  print('Implementando modelos principales para Logdoor...');

  final models = {
    'lib/core/models/warehouse.dart': '''
class Warehouse {
  final String id;
  final String name;
  final String location;
  final String? description;
  final String address;
  final Map<String, dynamic> coordinates;
  final bool isActive;
  final DateTime created;
  final DateTime updated;
  
  Warehouse({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    required this.address,
    required this.coordinates,
    required this.isActive,
    required this.created,
    required this.updated,
  });
  
  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      description: json['description'],
      address: json['address'],
      coordinates: json['coordinates'],
      isActive: json['isActive'] ?? true,
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'address': address,
      'coordinates': coordinates,
      'isActive': isActive,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }
}
''',
    'lib/core/models/access.dart': '''
import 'package:intl/intl.dart';

class Access {
  final String id;
  final String userId;
  final String userName;
  final String warehouseId;
  final String warehouseName;
  final String accessType; // 'entry' or 'exit'
  final Map<String, dynamic>? vehicleData;
  final Map<String, dynamic> geolocation;
  final String accessCode;
  final DateTime timestamp;
  final bool isSync;
  
  Access({
    required this.id,
    required this.userId,
    required this.userName,
    required this.warehouseId,
    required this.warehouseName,
    required this.accessType,
    this.vehicleData,
    required this.geolocation,
    required this.accessCode,
    required this.timestamp,
    required this.isSync,
  });
  
  factory Access.fromJson(Map<String, dynamic> json) {
    return Access(
      id: json['id'] ?? '',
      userId: json['user'],
      userName: json['userName'] ?? 'Unknown',
      warehouseId: json['warehouse'],
      warehouseName: json['warehouseName'] ?? 'Unknown',
      accessType: json['accessType'],
      vehicleData: json['vehicleData'],
      geolocation: json['geolocation'],
      accessCode: json['accessCode'],
      timestamp: DateTime.parse(json['timestamp']),
      isSync: json['isSync'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'userName': userName,
      'warehouse': warehouseId,
      'warehouseName': warehouseName,
      'accessType': accessType,
      'vehicleData': vehicleData,
      'geolocation': geolocation,
      'accessCode': accessCode,
      'timestamp': timestamp.toIso8601String(),
      'isSync': isSync,
    };
  }
  
  String get formattedTimestamp {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(timestamp);
  }
}
''',
    'lib/core/models/inspection.dart': '''
import 'package:intl/intl.dart';

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
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(timestamp);
  }
  
  bool get hasIssues {
    // Verificar si algún elemento de la lista tiene estado 'Mal' o 'Revisar'
    return checklist.values.any((item) => 
      item is Map<String, dynamic> && 
      item['status'] != null && 
      (item['status'] == 'Mal' || item['status'] == 'Revisar'));
  }
}
''',
    'lib/core/models/report.dart': '''
import 'package:intl/intl.dart';

class Report {
  final String id;
  final String inspectionId;
  final DateTime generatedAt;
  final String pdfReport;
  final String generatedById;
  final String generatedByName;
  
  Report({
    required this.id,
    required this.inspectionId,
    required this.generatedAt,
    required this.pdfReport,
    required this.generatedById,
    required this.generatedByName,
  });
  
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      inspectionId: json['inspection'],
      generatedAt: DateTime.parse(json['generatedAt']),
      pdfReport: json['pdfReport'],
      generatedById: json['generatedBy'],
      generatedByName: json['generatedByName'] ?? 'Unknown',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inspection': inspectionId,
      'generatedAt': generatedAt.toIso8601String(),
      'pdfReport': pdfReport,
      'generatedBy': generatedById,
      'generatedByName': generatedByName,
    };
  }
  
  String get formattedGeneratedAt {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(generatedAt);
  }
}
''',
    'lib/core/models/alert.dart': '''
import 'package:intl/intl.dart';

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
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
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
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(timestamp);
  }
  
  bool get isActive => status == 'active';
  bool get isResolved => status == 'resolved';
  bool get isFalseAlarm => status == 'false_alarm';
}
'''
  };

  // Crear archivos de modelos
  for (final entry in models.entries) {
    final file = File(entry.key);
    if (!await file.exists()) {
      await file.writeAsString(entry.value);
      print('✅ Modelo creado: ${entry.key}');
    } else {
      print('ℹ️ Modelo ya existe: ${entry.key}');
    }
  }

  print('\n✨ Modelos principales implementados exitosamente ✨');
}
