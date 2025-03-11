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
    return Warehouse(
      id: record.id,
      name: record.data['name'],
      location: record.data['location'],
      description: record.data['description'],
      address: record.data['address'],
      coordinates: record.data['coordinates'],
      isActive: record.data['isActive'] ?? true,
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
    );
  }

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
