// lib/features/inspections/screens/inspection_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/models/inspection.dart';
import '../../../core/models/access.dart';
import '../providers/inspection_provider.dart';
import '../../reports/providers/report_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';

class InspectionDetailScreen extends StatefulWidget {
  final String inspectionId;

  const InspectionDetailScreen({
    Key? key,
    required this.inspectionId,
  }) : super(key: key);

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  Inspection? _inspection;
  Access? _access;
  bool _isLoading = true;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _loadInspectionData();
  }

  Future<void> _loadInspectionData() async {
    final inspectionProvider =
        Provider.of<InspectionProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar inspección
      _inspection =
          await inspectionProvider.getInspectionById(widget.inspectionId);

      // TODO: Cargar el acceso relacionado (esto debería implementarse)
      // if (_inspection != null) {
      //   _access = await accessProvider.getAccessById(_inspection!.accessId);
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateReport() async {
    if (_inspection == null) return;

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final report = await reportProvider.generateReport(
        _inspection!,
        authProvider.currentUser!.id,
        authProvider.currentUser!.name,
      );

      if (report != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte generado exitosamente')),
        );

        // Navegar a la vista del reporte
        Navigator.of(context).pushNamed(
          '/reports/view',
          arguments: {'reportId': report.id},
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar reporte: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Inspección'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generar Reporte',
            onPressed: _isGeneratingReport ? null : _generateReport,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(text: 'Cargando detalles...')
          : _inspection == null
              ? const Center(child: Text('No se encontró la inspección'))
              : _buildInspectionDetails(),
    );
  }

  Widget _buildInspectionDetails() {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de información general
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información General',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildInfoRow('Inspector', _inspection!.inspectorName),
                  _buildInfoRow(
                      'Fecha', formatter.format(_inspection!.timestamp)),
                  _buildInfoRow('Estado', _getStatusText(_inspection!.status)),
                  _buildInfoRow(
                    'Problemas Detectados',
                    _inspection!.hasIssues ? 'Sí' : 'No',
                  ),
                  _buildInfoRow(
                    'Sincronizado',
                    _inspection!.isSync ? 'Sí' : 'No',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de verificación
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lista de Verificación CTPAT',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ..._buildChecklistItems(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Fotos
          if (_inspection!.photos.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evidencia Fotográfica',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _inspection!.photos.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _showFullScreenImage(_inspection!.photos[index]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_inspection!.photos[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Notas
          if (_inspection!.notes != null && _inspection!.notes!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notas Adicionales',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    Text(_inspection!.notes!),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Firma
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firma Digital',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_inspection!.signature!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botón para generar reporte
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(_isGeneratingReport
                  ? 'Generando reporte...'
                  : 'Generar Reporte PDF'),
              onPressed: _isGeneratingReport ? null : _generateReport,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChecklistItems() {
    final items = <Widget>[];
    final checklist = _inspection!.checklist;

    checklist.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final itemTitle = _getChecklistItemTitle(key);
        final status = value['status'] as String? ?? 'No especificado';
        final comments = value['comments'] as String? ?? '';

        items.add(
          ExpansionTile(
            title: Text(itemTitle),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: _getStatusColor(status)),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (comments.isNotEmpty) ...[
                      Text(
                        'Comentarios:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(comments),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }
    });

    if (items.isEmpty) {
      return [const Text('No hay datos de lista de verificación')];
    }

    return items;
  }

  void _showFullScreenImage(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.file(File(imagePath)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getChecklistItemTitle(String key) {
    final titles = {
      'front_bumper': 'Defensa Frontal',
      'engine': 'Compartimento del Motor',
      'tires': 'Llantas y Rines',
      'fuel_tank': 'Tanque de Combustible',
      'cabin': 'Interior de Cabina',
      'cargo': 'Área de Carga',
      'undercarriage': 'Chasis',
      'roof': 'Techo',
      'doors': 'Puertas y Cerraduras',
      'refrigeration': 'Unidad de Refrigeración',
      'fifth_wheel': 'Quinta Rueda',
      'compartments': 'Compartimentos',
      'floor': 'Piso (Interior)',
      'ceiling': 'Techo (Interior)',
      'right_wall': 'Pared Derecha',
      'left_wall': 'Pared Izquierda',
      'front_wall': 'Pared Frontal',
      'seals': 'Sellos de Seguridad',
    };

    return titles[key] ?? key;
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'completed':
        return 'Completada';
      case 'flagged':
        return 'Marcada';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Bien':
        return Colors.green;
      case 'Mal':
        return Colors.red;
      case 'Revisar':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
