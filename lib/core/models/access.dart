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

  factory Access.fromRecord(dynamic record) {
    // Para registros PocketBase con relaciones expandidas
    String userName = 'Unknown';
    String warehouseName = 'Unknown';

    if (record.expand != null && record.expand['user'] != null) {
      userName = record.expand['user'].data['name'];
    }

    if (record.expand != null && record.expand['warehouse'] != null) {
      warehouseName = record.expand['warehouse'].data['name'];
    }

    return Access(
      id: record.id,
      userId: record.data['user'],
      userName: userName,
      warehouseId: record.data['warehouse'],
      warehouseName: warehouseName,
      accessType: record.data['accessType'],
      vehicleData: record.data['vehicleData'],
      geolocation: record.data['geolocation'],
      accessCode: record.data['accessCode'],
      timestamp: DateTime.parse(record.data['timestamp']),
      isSync: record.data['isSync'] ?? true,
    );
  }

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
