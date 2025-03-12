import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/inspection.dart';
import '../utils/logger.dart';
import 'dart:typed_data';

class PdfService {
  // Generar un reporte PDF para una inspección
  Future<String> generateInspectionReport(Inspection inspection) async {
    try {
      Logger.info(
          'Iniciando generación de PDF para inspección: ${inspection.id}');

      final pdf = pw.Document();

      // Agregar contenido al reporte
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            _buildHeader(inspection),
            _buildInspectionDetails(inspection),
            _buildChecklist(inspection),
            _buildPhotosSection(inspection),
            _buildNotes(inspection),
            _buildSignature(inspection),
          ],
          footer: (context) => _buildFooter(context),
        ),
      );

      // Guardar el PDF en un archivo temporal
      final tempDir = await getTemporaryDirectory();
      final reportName =
          'inspection_${inspection.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
      final reportPath = '${tempDir.path}/$reportName';
      final file = File(reportPath);

      Logger.info('Guardando PDF en: $reportPath');
      await file.writeAsBytes(await pdf.save());

      Logger.info('Reporte PDF generado: $reportPath');
      return reportPath;
    } catch (e) {
      Logger.error('Error al generar reporte PDF', error: e);
      rethrow;
    }
  }

  pw.Widget _buildHeader(Inspection inspection) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CTPAT Inspection Report',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'ID: ${inspection.id}',
            style: pw.TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInspectionDetails(Inspection inspection) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20, bottom: 20),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Inspection Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Inspector: ${inspection.inspectorName}'),
                  pw.Text('Date: ${formatter.format(inspection.timestamp)}'),
                  pw.Text('Status: ${inspection.status}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Access ID: ${inspection.accessId}'),
                  pw.Text('Has Issues: ${inspection.hasIssues ? "Yes" : "No"}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildChecklist(Inspection inspection) {
    final checklist = inspection.checklist;
    final items = checklist.entries.toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Inspection Checklist',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(3),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Item',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Status',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Comments',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),

            // Checklist items
            ...items.map((entry) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_getItemTitle(entry.key)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_getItemStatus(entry.value)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_getItemComments(entry.value)),
                    ),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  // Nuevo método para incluir fotos en el PDF
  pw.Widget _buildPhotosSection(Inspection inspection) {
    if (inspection.photos.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Evidence Photos',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Inspection includes ${inspection.photos.length} photos (not shown in this PDF for size reasons)',
          style: pw.TextStyle(
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        // No añadimos las fotos reales al PDF para evitar archivos muy grandes
        // En una implementación real, podría incluir fotos comprimidas o solo las más relevantes
      ],
    );
  }

  String _getItemTitle(String key) {
    // Map key names to human-readable titles
    final titles = {
      'front_bumper': 'Front Bumper/Defense',
      'engine': 'Engine Compartment',
      'tires': 'Tires and Rims',
      'fuel_tank': 'Fuel Tank',
      'cabin': 'Cabin Interior',
      'cargo': 'Cargo Area',
      'undercarriage': 'Undercarriage',
      'roof': 'Roof',
      'doors': 'Doors and Locks',
      'refrigeration': 'Refrigeration Unit',
      'fifth_wheel': 'Fifth Wheel',
      'compartments': 'External/Internal Compartments',
      'floor': 'Floor (Inside)',
      'ceiling': 'Ceiling/Roof (Inside)',
      'right_wall': 'Right Side Wall',
      'left_wall': 'Left Side Wall',
      'front_wall': 'Front Wall',
      'seals': 'Security Seals',
    };

    return titles[key] ?? key;
  }

  String _getItemStatus(dynamic value) {
    if (value is Map<String, dynamic> && value['status'] != null) {
      return value['status'];
    }
    return '';
  }

  String _getItemComments(dynamic value) {
    if (value is Map<String, dynamic> && value['comments'] != null) {
      return value['comments'];
    }
    return '';
  }

  pw.Widget _buildNotes(Inspection inspection) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20, bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Additional Notes',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(inspection.notes ?? 'No additional notes.'),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignature(Inspection inspection) {
    // En una implementación real, cargaríamos la imagen de firma
    // Por ahora, solo agregar un marcador de posición
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Digital Signature',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 70,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Center(
              child: pw.Text('Signed digitally by ${inspection.inspectorName}'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated: ${formatter.format(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
