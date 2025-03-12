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

  factory Warehouse.fromRecord(dynamic record) {
    Map<String, dynamic> safeCoordinates;

    // Manejo seguro de coordinates que puede ser null
    if (record.data['coordinates'] == null) {
      safeCoordinates = {'latitude': 0.0, 'longitude': 0.0};
    } else {
      safeCoordinates = record.data['coordinates'] as Map<String, dynamic>;
    }

    return Warehouse(
      id: record.id,
      name: record.data['name'] ?? '',
      location: record.data['location'] ?? '',
      description: record.data['description'] ?? '',
      address: record.data['address'] ?? '',
      coordinates: safeCoordinates,
      isActive: record.data['isActive'] ?? true,
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
    );
  }

  // Asegúrate de que el método fromJson también maneje el caso null para coordinates
  factory Warehouse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> safeCoordinates;

    // Manejo seguro de coordinates que puede ser null
    if (json['coordinates'] == null) {
      safeCoordinates = {'latitude': 0.0, 'longitude': 0.0};
    } else {
      safeCoordinates = json['coordinates'] as Map<String, dynamic>;
    }

    return Warehouse(
      id: json['id'],
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      description: json['description'],
      address: json['address'] ?? '',
      coordinates: safeCoordinates,
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
