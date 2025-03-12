// lib/features/reports/screens/report_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/report.dart';
import '../providers/report_provider.dart';
import '../widgets/pdf_viewer.dart';
import '../../../shared/widgets/loading_indicator.dart';

class ReportViewerScreen extends StatefulWidget {
  final String reportId;

  const ReportViewerScreen({
    Key? key,
    required this.reportId,
  }) : super(key: key);

  @override
  State<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  bool _isLoading = true;
  Report? _report;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      _report = await reportProvider.getReportById(widget.reportId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar reporte: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareReport() async {
    if (_report == null) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);
      final success = await reportProvider.shareReport(_report!);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte compartido exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir reporte: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(text: 'Cargando reporte...'),
      );
    }

    if (_report == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reporte no encontrado'),
        ),
        body: const Center(
          child: Text('No se pudo encontrar el reporte solicitado'),
        ),
      );
    }

    return PdfViewerWidget(
      pdfPath: _report!.pdfReport,
      title: 'Reporte de Inspección',
      onShare: _isSharing ? null : _shareReport,
    );
  }
}
