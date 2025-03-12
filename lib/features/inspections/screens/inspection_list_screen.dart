// lib/features/inspections/screens/inspection_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/inspection.dart';
import '../providers/inspection_provider.dart';
import '../../auth/providers/auth_provider.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({Key? key}) : super(key: key);

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String? _filterStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Cargar datos cuando se inicializa el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInspections();
    });
  }

  Future<void> _loadInspections() async {
    final inspectionProvider =
        Provider.of<InspectionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await inspectionProvider.getInspections(
        inspectorId: authProvider.currentUser!.isInspector
            ? authProvider.currentUser!.id
            : null,
        fromDate: _dateRange.start,
        toDate: _dateRange.end,
        status: _filterStatus,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al cargar inspecciones: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspectionProvider = Provider.of<InspectionProvider>(context);
    final inspections = inspectionProvider.inspections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspecciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInspections,
          ),
        ],
      ),
      body: Column(
        children: [
          // Mostrar filtros activos
          if (_filterStatus != null ||
              _dateRange.start !=
                  DateTime.now().subtract(const Duration(days: 30))) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtros: ${_filterStatus != null ? 'Estado: ${_getStatusText(_filterStatus!)}' : ''}'
                      '${_dateRange.start != DateTime.now().subtract(const Duration(days: 30)) ? ' Rango de fechas' : ''}',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterStatus = null;
                        _dateRange = DateTimeRange(
                          start:
                              DateTime.now().subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        );
                      });
                      _loadInspections();
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
          ],

          // Lista de inspecciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : inspections.isEmpty
                    ? const Center(
                        child: Text('No hay inspecciones para mostrar'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadInspections,
                        child: ListView.builder(
                          itemCount: inspections.length,
                          itemBuilder: (context, index) {
                            return _buildInspectionCard(inspections[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/access/scan');
        },
        tooltip: 'Escanear QR para inspección',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildInspectionCard(Inspection inspection) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: _getStatusIconColor(inspection.status),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Inspección ${inspection.hasIssues ? '(Problemas)' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Inspector: ${inspection.inspectorName}'),
            Text('Fecha: ${formatter.format(inspection.timestamp)}'),
            Text('Estado: ${_getStatusText(inspection.status)}'),
            if (!inspection.isSync)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_problem,
                        size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 4),
                    Text(
                      'Pendiente de sincronizar',
                      style:
                          TextStyle(fontSize: 12, color: Colors.amber.shade800),
                    ),
                  ],
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.of(context).pushNamed(
            '/inspection/detail',
            arguments: {'inspectionId': inspection.id},
          );
        },
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedStatus = _filterStatus;
        DateTimeRange selectedDateRange = _dateRange;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrar Inspecciones'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filtro por estado
                    const Text('Estado'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'completed',
                          child: Text('Completadas'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'pending',
                          child: Text('Pendientes'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'flagged',
                          child: Text('Marcadas'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filtro por fecha
                    const Text('Rango de Fechas'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        '${selectedDateRange.start.day}/${selectedDateRange.start.month} - ${selectedDateRange.end.day}/${selectedDateRange.end.month}',
                      ),
                      onPressed: () async {
                        final result = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                          initialDateRange: selectedDateRange,
                        );

                        if (result != null) {
                          setState(() {
                            selectedDateRange = result;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _filterStatus = selectedStatus;
                      _dateRange = selectedDateRange;
                    });
                    Navigator.of(context).pop();
                    _loadInspections();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
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

  Color _getStatusIconColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'flagged':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
