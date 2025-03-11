// lib/features/inspections/widgets/checklist_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChecklistItem extends StatefulWidget {
  final String title;
  final String description;
  final String formField;
  final Function(XFile) onPhotoTaken;

  const ChecklistItem({
    Key? key,
    required this.title,
    required this.description,
    required this.formField,
    required this.onPhotoTaken,
  }) : super(key: key);

  @override
  State<ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<ChecklistItem> {
  List<XFile> _photos = [];
  final _imagePicker = ImagePicker();
  String _selectedStatus = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y descripción
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),

            const SizedBox(height: 16),

            // Selección de estado (Bien/Mal/Revisar)
            Row(
              children: [
                Expanded(
                  child: FormBuilderRadioGroup<String>(
                    name: '${widget.formField}.status',
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    options: const [
                      FormBuilderFieldOption(
                        value: 'Bien',
                        child: Text('Bien'),
                      ),
                      FormBuilderFieldOption(
                        value: 'Mal',
                        child: Text('Mal'),
                      ),
                      FormBuilderFieldOption(
                        value: 'Revisar',
                        child: Text('Revisar'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),

            // Campo de comentarios
            FormBuilderTextField(
              name: '${widget.formField}.comments',
              decoration: const InputDecoration(
                labelText: 'Comentarios',
                hintText: 'Ingrese observaciones o notas',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Sección de fotos de evidencia
            Row(
              children: [
                Text(
                  'Fotos de Evidencia',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar Foto'),
                  onPressed: _takePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Vista previa de fotos
            if (_photos.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _photos.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_photos[index].path),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            // Almacenar rutas de fotos en un campo de formulario oculto
            FormBuilderField<List<String>>(
              name: '${widget.formField}.photos',
              builder: (field) => const SizedBox.shrink(),
              initialValue: _photos.map((photo) => photo.path).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          _photos.add(photo);
        });

        // Llamar al callback para notificar al padre
        widget.onPhotoTaken(photo);
      }
    } catch (e) {
      print('Error al tomar foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar foto: $e')),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }
}
