// lib/features/access_control/screens/access_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/access_provider.dart';
import '../../../core/models/access.dart';
import '../../../core/models/warehouse.dart';
import '../../../features/settings/providers/settings_provider.dart';

class AccessListScreen extends StatefulWidget {
  const AccessListScreen({Key? key}) : super(key: key);

  @override
  State<AccessListScreen> createState() => _AccessListScreenState();
}

class _AccessListScreenState extends State<AccessListScreen> {
  Warehouse? _selectedWarehouse;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  bool _isLoading = true;
  String? _filterAccessType;

  @override
  void initState() {
    super.initState();

    // Cargar datos cuando se inicializa el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).loadWarehouses();
      _loadAccessList();
    });
  }

  Future<void> _loadAccessList() async {
    final accessProvider = Provider.of<AccessProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await accessProvider.getAccesses(
        warehouseId: _selectedWarehouse?.id,
        fromDate: _dateRange.start,
        toDate: _dateRange.end,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar accesos: ${e.toString()}')),
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
    final accessProvider = Provider.of<AccessProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Filtrar por tipo de acceso si está seleccionado
    final filteredAccessList = _filterAccessType != null
        ? accessProvider.accessList
            .where((a) => a.accessType == _filterAccessType)
            .toList()
        : accessProvider.accessList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Accesos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccessList,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros aplicados
          if (_selectedWarehouse != null || _filterAccessType != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Filtros: ${_selectedWarehouse != null ? _selectedWarehouse!.name : ''} ${_filterAccessType != null ? (_filterAccessType == 'entry' ? 'Entradas' : 'Salidas') : ''}'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedWarehouse = null;
                        _filterAccessType = null;
                      });
                      _loadAccessList();
                    },
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
          ],

          // Lista de accesos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAccessList.isEmpty
                    ? const Center(child: Text('No hay accesos registrados'))
                    : RefreshIndicator(
                        onRefresh: _loadAccessList,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredAccessList.length,
                          itemBuilder: (context, index) {
                            final access = filteredAccessList[index];
                            return _buildAccessCard(context, access);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/access/new');
        },
        tooltip: 'Nuevo Acceso',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAccessCard(BuildContext context, Access access) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              access.accessType == 'entry' ? Colors.green : Colors.blue,
          child: Icon(
            access.accessType == 'entry' ? Icons.login : Icons.logout,
            color: Colors.white,
          ),
        ),
        title: Text(
          access.accessType == 'entry' ? 'Entrada' : 'Salida',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conductor: ${access.vehicleData?['driver'] ?? 'N/A'}'),
            Text('Placa: ${access.vehicleData?['plate'] ?? 'N/A'}'),
            Text('Almacén: ${access.warehouseName}'),
            Text('Hora: ${formatter.format(access.timestamp)}'),
            if (!access.isSync)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Pendiente de sincronizar',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.qr_code),
          onPressed: () {
            Navigator.of(context).pushNamed(
              '/access/qr',
              arguments: {'access': access},
            );
          },
          tooltip: 'Ver código QR',
        ),
        isThreeLine: true,
        onTap: () {
          // Mostrar detalles del acceso o ir a pantalla de detalles
          _showAccessDetails(context, access);
        },
      ),
    );
  }

  void _showFilterDialog() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrar Accesos'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Almacén'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Warehouse?>(
                      value: _selectedWarehouse,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<Warehouse?>(
                          value: null,
                          child: Text('Todos los almacenes'),
                        ),
                        ...settingsProvider.warehouses.map((warehouse) {
                          return DropdownMenuItem<Warehouse>(
                            value: warehouse,
                            child: Text(warehouse.name),
                          );
                        }).toList(),
                      ],
                      onChanged: (warehouse) {
                        setState(() {
                          _selectedWarehouse = warehouse;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Tipo de Acceso'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _filterAccessType,
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
                          value: 'entry',
                          child: Text('Entradas'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'exit',
                          child: Text('Salidas'),
                        ),
                      ],
                      onChanged: (accessType) {
                        setState(() {
                          _filterAccessType = accessType;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Rango de Fechas'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        '${_dateRange.start.day}/${_dateRange.start.month} - ${_dateRange.end.day}/${_dateRange.end.month}',
                      ),
                      onPressed: () async {
                        final result = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                          initialDateRange: _dateRange,
                        );

                        if (result != null) {
                          setState(() {
                            _dateRange = result;
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
                    Navigator.of(context).pop();
                    _loadAccessList();
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

  void _showAccessDetails(BuildContext context, Access access) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(access.accessType == 'entry'
              ? 'Detalle de Entrada'
              : 'Detalle de Salida'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Código', access.accessCode),
                _buildDetailRow('Almacén', access.warehouseName),
                _buildDetailRow(
                    'Fecha y hora', formatter.format(access.timestamp)),
                _buildDetailRow(
                    'Conductor', access.vehicleData?['driver'] ?? 'N/A'),
                _buildDetailRow('Placa', access.vehicleData?['plate'] ?? 'N/A'),
                _buildDetailRow(
                    'Tipo de vehículo', access.vehicleData?['type'] ?? 'N/A'),
                _buildDetailRow('Sincronizado', access.isSync ? 'Sí' : 'No'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Ver código QR'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(
                      '/access/qr',
                      arguments: {'access': access},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
}
