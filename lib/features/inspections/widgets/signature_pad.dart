// lib/features/inspections/widgets/signature_pad.dart
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SignaturePad extends StatefulWidget {
  final Function(String) onSigned;

  const SignaturePad({Key? key, required this.onSigned}) : super(key: key);

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = [];
  bool _isSigned = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Área de firma
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox renderBox = context.findRenderObject() as RenderBox;
                Offset localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                _points.add(localPosition);
                _isSigned = true;
              });
            },
            onPanEnd: (details) => _points.add(null),
            child: CustomPaint(
              painter: SignaturePainter(points: _points),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Botones
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar'),
              onPressed: _clear,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Guardar Firma'),
              onPressed: _isSigned ? _saveSignature : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _clear() {
    setState(() {
      _points.clear();
      _isSigned = false;
    });
  }

  Future<void> _saveSignature() async {
    try {
      // Crear un límite alrededor de la firma
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Definir tamaño del canvas
      final size = Size(context.size!.width, 200);

      // Pintar la firma
      final signaturePainter = SignaturePainter(points: _points);
      signaturePainter.paint(canvas, size);

      // Convertir a imagen
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final imageData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = imageData!.buffer.asUint8List();

      // Guardar en archivo
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${appDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Llamar al callback con la ruta del archivo
      widget.onSigned(file.path);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firma guardada')),
      );
    } catch (e) {
      print('Error al guardar firma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar firma: $e')),
      );
    }
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(ui.PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
