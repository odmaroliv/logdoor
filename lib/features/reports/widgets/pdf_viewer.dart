// lib/features/reports/widgets/pdf_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import '../../../shared/widgets/loading_indicator.dart';

class PdfViewerWidget extends StatefulWidget {
  final String pdfPath;
  final String title;
  final VoidCallback? onShare;

  const PdfViewerWidget({
    Key? key,
    required this.pdfPath,
    required this.title,
    this.onShare,
  }) : super(key: key);

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  bool _isLoading = true;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.onShare != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: widget.onShare,
            ),
        ],
      ),
      body: Stack(
        children: [
          // PDF viewer
          _buildPdfView(),

          // Loading indicator
          if (_isLoading) const LoadingIndicator(text: 'Cargando documento...'),

          // Page indicator
          if (!_isLoading && _totalPages > 0)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Página ${_currentPage + 1} de $_totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    final File pdfFile = File(widget.pdfPath);

    // Verificar si el archivo existe
    if (!pdfFile.existsSync()) {
      return const Center(
        child: Text('El archivo PDF no existe.'),
      );
    }

    return PDFView(
      filePath: widget.pdfPath,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          _isLoading = false;
          _totalPages = pages!;
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar PDF: $error')),
        );
      },
      onPageError: (page, error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en página $page: $error')),
        );
      },
      onViewCreated: (PDFViewController controller) {
        _pdfController = controller;
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page!;
        });
      },
    );
  }
}
