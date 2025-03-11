// lib/features/access_control/screens/access_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/models/user.dart';
import '../../../core/services/geolocation_service.dart';
import '../providers/access_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../widgets/vehicle_form.dart';

class AccessFormScreen extends StatefulWidget {
  const AccessFormScreen({Key? key}) : super(key: key);

  @override
  State<AccessFormScreen> createState() => _AccessFormScreenState();
}

class _AccessFormScreenState extends State<AccessFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _vehicleFormKey = GlobalKey<FormBuilderState>();
  final _geolocationService = GeolocationService();

  bool _isLoading = false;
  String? _accessType = 'entry';
  Warehouse? _selectedWarehouse;

  @override
  void initState() {
    super.initState();
    // Cargar almacenes si aún no se han cargado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      if (settingsProvider.warehouses.isEmpty) {
        settingsProvider.loadWarehouses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final accessProvider = Provider.of<AccessProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Acceso'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Formulario principal
                  FormBuilder(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tipo de acceso
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tipo de Acceso',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                FormBuilderRadioGroup<String>(
                                  name: 'accessType',
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  initialValue: _accessType,
                                  options: const [
                                    FormBuilderFieldOption(
                                      value: 'entry',
                                      child: Text('Entrada'),
                                    ),
                                    FormBuilderFieldOption(
                                      value: 'exit',
                                      child: Text('Salida'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _accessType = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Selección de almacén
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Almacén',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                FormBuilderDropdown<Warehouse>(
                                  name: 'warehouse',
                                  decoration: const InputDecoration(
                                    labelText: 'Seleccione un almacén',
                                    prefixIcon: Icon(Icons.warehouse),
                                  ),
                                  items: settingsProvider.warehouses
                                      .map((warehouse) {
                                    return DropdownMenuItem(
                                      value: warehouse,
                                      child: Text(warehouse.name),
                                    );
                                  }).toList(),
                                  validator: FormBuilderValidators.compose([
                                    FormBuilderValidators.required(
                                        errorText: 'Seleccione un almacén'),
                                  ]),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedWarehouse = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Formulario del vehículo
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: VehicleForm(
                              formKey: _vehicleFormKey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mensajes de error
                        if (accessProvider.error != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              accessProvider.error!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Botón de registrar acceso
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: accessProvider.isLoading
                                ? null
                                : () => _submitForm(user, accessProvider),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: accessProvider.isLoading
                                ? const CircularProgressIndicator()
                                : Text(_accessType == 'entry'
                                    ? 'Registrar Entrada'
                                    : 'Registrar Salida'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _submitForm(User? user, AccessProvider accessProvider) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    final mainFormValid = _formKey.currentState?.saveAndValidate() ?? false;
    final vehicleFormValid =
        _vehicleFormKey.currentState?.saveAndValidate() ?? false;

    if (!mainFormValid || !vehicleFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor complete todos los campos requeridos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final mainFormData = _formKey.currentState!.value;
      final vehicleFormData = _vehicleFormKey.currentState!.value;
      final warehouse = mainFormData['warehouse'] as Warehouse;

      // Crear acceso
      final access = await accessProvider.createAccess(
        userId: user.id,
        userName: user.name,
        warehouseId: warehouse.id,
        warehouseName: warehouse.name,
        accessType: mainFormData['accessType'],
        vehicleData: vehicleFormData,
      );

      if (access != null && mounted) {
        // Navegar a la pantalla de código QR
        Navigator.of(context).pushReplacementNamed(
          '/access/qr',
          arguments: {'access': access},
        );
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
