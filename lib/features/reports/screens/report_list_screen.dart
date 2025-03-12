// lib/features/reports/screens/report_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/report.dart';
import '../providers/report_provider.dart';
import '../widgets/report_card.dart';
import '../../auth/providers/auth_provider.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({Key? key}) : super(key: key);

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Cargar datos cuando se inicializa el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await reportProvider.getReports(
        generatedById: authProvider.currentUser!.isInspector
            ? authProvider.currentUser!.id
            : null,
        fromDate: _dateRange.start,
        toDate: _dateRange.end,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar reportes: ${e.toString()}')),
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
    final reportProvider = Provider.of<ReportProvider>(context);
    final reports = reportProvider.reports;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateFilter,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Mostrar filtros activos
          if (_dateRange.start !=
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
                      'Filtro: Rango de fechas ${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _dateRange = DateTimeRange(
                          start:
                              DateTime.now().subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        );
                      });
                      _loadReports();
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
          ],

          // Lista de reportes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : reports.isEmpty
                    ? const Center(
                        child: Text('No hay reportes para mostrar'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: reports.length,
                          itemBuilder: (context, index) {
                            return ReportCard(
                              report: reports[index],
                              onTap: () => _openReport(reports[index]),
                              onShare: () => _shareReport(reports[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showDateFilter() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (result != null) {
      setState(() {
        _dateRange = result;
      });
      _loadReports();
    }
  }

  void _openReport(Report report) {
    Navigator.of(context).pushNamed(
      '/reports/view',
      arguments: {'reportId': report.id},
    );
  }

  Future<void> _shareReport(Report report) async {
    try {
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);
      final success = await reportProvider.shareReport(report);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte compartido exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir reporte: ${e.toString()}')),
      );
    }
  }
}
