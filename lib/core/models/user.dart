class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phoneNumber;
  final Map<String, dynamic>? biometricData;
  final String? profilePicture;
  final DateTime created;
  final DateTime updated;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.biometricData,
    this.profilePicture,
    required this.created,
    required this.updated,
  });

  factory User.fromRecord(dynamic record) {
    return User(
      id: record.id?.toString() ?? '', // Convierte a String si es necesario
      name: record.data['name']?.toString() ??
          '', // Convierte a String si es necesario
      email: record.data['email']?.toString() ??
          '', // Convierte a String si es necesario
      role: record.data['role']?.toString() ??
          '', // Convierte a String si es necesario
      phoneNumber: record.data['phoneNumber']
          ?.toString(), // Convierte a String si es necesario
      biometricData: record.data['biometricData'],
      profilePicture: record.data['profilePicture'],
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '', // Convierte a String si es necesario
      name:
          json['name']?.toString() ?? '', // Convierte a String si es necesario
      email:
          json['email']?.toString() ?? '', // Convierte a String si es necesario
      role:
          json['role']?.toString() ?? '', // Convierte a String si es necesario
      phoneNumber:
          json['phoneNumber']?.toString(), // Convierte a String si es necesario
      biometricData: json['biometricData'],
      profilePicture: json['profilePicture'],
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'biometricData': biometricData,
      'profilePicture': profilePicture,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isInspector => role == 'inspector';
  bool get isGuard => role == 'guard';
  bool get isVisitor => role == 'visitor';
}
