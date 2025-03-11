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

  factory Report.fromRecord(dynamic record) {
    String generatedByName = 'Unknown';

    if (record.expand != null && record.expand['generatedBy'] != null) {
      generatedByName = record.expand['generatedBy'].data['name'];
    }

    return Report(
      id: record.id,
      inspectionId: record.data['inspection'],
      generatedAt: DateTime.parse(record.data['generatedAt']),
      pdfReport: record.data['pdfReport'],
      generatedById: record.data['generatedBy'],
      generatedByName: generatedByName,
    );
  }

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
    return '${generatedAt.day}/${generatedAt.month}/${generatedAt.year} ${generatedAt.hour}:${generatedAt.minute.toString().padLeft(2, '0')}';
  }
}
