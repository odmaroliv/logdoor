// lib/features/settings/screens/warehouse_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../core/models/warehouse.dart';
import '../providers/settings_provider.dart';

class WarehouseSettingsScreen extends StatefulWidget {
  const WarehouseSettingsScreen({Key? key}) : super(key: key);

  @override
  State<WarehouseSettingsScreen> createState() =>
      _WarehouseSettingsScreenState();
}

class _WarehouseSettingsScreenState extends State<WarehouseSettingsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isCreating = false;
  bool _isEditing = false;
  bool _isLoading = false;
  Warehouse? _selectedWarehouse;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final warehouses = settingsProvider.warehouses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Almacenes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Lista de almacenes
                if (!_isCreating && !_isEditing) ...[
                  Expanded(
                    child: warehouses.isEmpty
                        ? const Center(
                            child: Text('No hay almacenes configurados'),
                          )
                        : ListView.builder(
                            itemCount: warehouses.length,
                            itemBuilder: (context, index) {
                              final warehouse = warehouses[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(warehouse.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Ubicación: ${warehouse.location}'),
                                      Text('Dirección: ${warehouse.address}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          setState(() {
                                            _selectedWarehouse = warehouse;
                                            _isEditing = true;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          warehouse.isActive
                                              ? Icons.toggle_on
                                              : Icons.toggle_off,
                                          color: warehouse.isActive
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        onPressed: () {
                                          _toggleWarehouseStatus(
                                            settingsProvider,
                                            warehouse,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedWarehouse = warehouse;
                                      _isEditing = true;
                                    });
                                  },
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                  ),

                  // Botón para agregar almacén
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Almacén'),
                        onPressed: () {
                          setState(() {
                            _isCreating = true;
                            _selectedWarehouse = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],

                // Formulario para crear o editar almacén
                if (_isCreating || _isEditing) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCreating ? 'Nuevo Almacén' : 'Editar Almacén',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildWarehouseForm(settingsProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildWarehouseForm(SettingsProvider settingsProvider) {
    return FormBuilder(
      key: _formKey,
      initialValue: _selectedWarehouse != null
          ? {
              'name': _selectedWarehouse!.name,
              'location': _selectedWarehouse!.location,
              'address': _selectedWarehouse!.address,
              'description': _selectedWarehouse!.description ?? '',
              'latitude':
                  _selectedWarehouse!.coordinates['latitude'].toString(),
              'longitude':
                  _selectedWarehouse!.coordinates['longitude'].toString(),
            }
          : {},
      child: Column(
        children: [
          FormBuilderTextField(
            name: 'name',
            decoration: const InputDecoration(
              labelText: 'Nombre del Almacén',
              border: OutlineInputBorder(),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText: 'El nombre es obligatorio'),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'location',
            decoration: const InputDecoration(
              labelText: 'Ubicación',
              border: OutlineInputBorder(),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText: 'La ubicación es obligatoria'),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'address',
            decoration: const InputDecoration(
              labelText: 'Dirección',
              border: OutlineInputBorder(),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText: 'La dirección es obligatoria'),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'description',
            decoration: const InputDecoration(
              labelText: 'Descripción (Opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'latitude',
                  decoration: const InputDecoration(
                    labelText: 'Latitud',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'La latitud es obligatoria'),
                    FormBuilderValidators.numeric(
                        errorText: 'Debe ser un número'),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderTextField(
                  name: 'longitude',
                  decoration: const InputDecoration(
                    labelText: 'Longitud',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                        errorText: 'La longitud es obligatoria'),
                    FormBuilderValidators.numeric(
                        errorText: 'Debe ser un número'),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isCreating = false;
                      _isEditing = false;
                      _selectedWarehouse = null;
                    });
                  },
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submitForm(settingsProvider),
                  child: Text(_isCreating ? 'Crear' : 'Actualizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm(SettingsProvider settingsProvider) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;

        final coordinates = {
          'latitude': double.parse(formData['latitude']),
          'longitude': double.parse(formData['longitude']),
        };

        if (_isCreating) {
          // Crear nuevo almacén
          await settingsProvider.createWarehouse(
            name: formData['name'],
            location: formData['location'],
            address: formData['address'],
            coordinates: coordinates,
            description: formData['description'],
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Almacén creado exitosamente')),
            );
          }
        } else if (_isEditing && _selectedWarehouse != null) {
          // Actualizar almacén existente
          await settingsProvider.updateWarehouse(
            warehouseId: _selectedWarehouse!.id,
            name: formData['name'],
            location: formData['location'],
            address: formData['address'],
            coordinates: coordinates,
            description: formData['description'],
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Almacén actualizado exitosamente')),
            );
          }
        }

        if (mounted) {
          setState(() {
            _isCreating = false;
            _isEditing = false;
            _selectedWarehouse = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _toggleWarehouseStatus(
    SettingsProvider settingsProvider,
    Warehouse warehouse,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (warehouse.isActive) {
        // Desactivar almacén
        await settingsProvider.deactivateWarehouse(warehouse.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Almacén desactivado')),
          );
        }
      } else {
        // Activar almacén
        await settingsProvider.updateWarehouse(
          warehouseId: warehouse.id,
          isActive: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Almacén activado')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
