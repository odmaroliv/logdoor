// lib/features/access_control/widgets/vehicle_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class VehicleForm extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final Map<String, dynamic>? initialValue;

  const VehicleForm({
    Key? key,
    required this.formKey,
    this.initialValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      initialValue: initialValue ?? {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Información del Vehículo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Conductor
          FormBuilderTextField(
            name: 'driver',
            decoration: const InputDecoration(
              labelText: 'Nombre del Conductor',
              hintText: 'Ingrese el nombre completo',
              prefixIcon: Icon(Icons.person),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Campo obligatorio'),
            ]),
          ),
          const SizedBox(height: 16),

          // Placa
          FormBuilderTextField(
            name: 'plate',
            decoration: const InputDecoration(
              labelText: 'Placa del Vehículo',
              hintText: 'Ej. ABC-123',
              prefixIcon: Icon(Icons.directions_car),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Campo obligatorio'),
            ]),
          ),
          const SizedBox(height: 16),

          // Tipo de vehículo
          FormBuilderDropdown<String>(
            name: 'type',
            decoration: const InputDecoration(
              labelText: 'Tipo de Vehículo',
              prefixIcon: Icon(Icons.local_shipping),
            ),
            items: const [
              DropdownMenuItem(
                value: 'car',
                child: Text('Automóvil'),
              ),
              DropdownMenuItem(
                value: 'truck',
                child: Text('Camión'),
              ),
              DropdownMenuItem(
                value: 'van',
                child: Text('Furgoneta'),
              ),
              DropdownMenuItem(
                value: 'motorcycle',
                child: Text('Motocicleta'),
              ),
              DropdownMenuItem(
                value: 'other',
                child: Text('Otro'),
              ),
            ],
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Seleccione un tipo'),
            ]),
          ),
          const SizedBox(height: 16),

          // Marca y modelo
          Row(
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: 'brand',
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    hintText: 'Ej. Toyota',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FormBuilderTextField(
                  name: 'model',
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    hintText: 'Ej. Corolla',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Color
          FormBuilderTextField(
            name: 'color',
            decoration: const InputDecoration(
              labelText: 'Color',
              hintText: 'Ej. Rojo',
              prefixIcon: Icon(Icons.color_lens),
            ),
          ),
          const SizedBox(height: 16),

          // Observaciones
          FormBuilderTextField(
            name: 'observations',
            decoration: const InputDecoration(
              labelText: 'Observaciones',
              hintText: 'Información adicional del vehículo',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
