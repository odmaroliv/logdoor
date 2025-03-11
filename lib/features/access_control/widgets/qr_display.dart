// lib/features/access_control/widgets/qr_display.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/models/access.dart';
import '../../../shared/widgets/custom_button.dart';

class QrDisplay extends StatelessWidget {
  final Access access;
  final VoidCallback? onShare;
  final VoidCallback? onPrint;

  const QrDisplay({
    Key? key,
    required this.access,
    this.onShare,
    this.onPrint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título
        Text(
          'Código de Acceso',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: QrImageView(
            data: access.accessCode,
            version: QrVersions.auto,
            size: 200.0,
            embeddedImage: const AssetImage('assets/images/logo_small.png'),
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size(40, 40),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Código numérico
        Text(
          'Código: ${access.accessCode}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
        ),
        const SizedBox(height: 24),

        // Información del acceso
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                  'Tipo', access.accessType == 'entry' ? 'Entrada' : 'Salida'),
              _buildInfoRow(
                  'Conductor', access.vehicleData?['driver'] ?? 'N/A'),
              _buildInfoRow('Placa', access.vehicleData?['plate'] ?? 'N/A'),
              _buildInfoRow('Almacén', access.warehouseName),
              _buildInfoRow('Fecha', access.formattedTimestamp),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Botones de acciones
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (onShare != null)
              Expanded(
                child: CustomButton(
                  text: 'Compartir',
                  icon: Icons.share,
                  onPressed: onShare!,
                ),
              ),
            if (onShare != null && onPrint != null) const SizedBox(width: 16),
            if (onPrint != null)
              Expanded(
                child: CustomButton(
                  text: 'Imprimir',
                  icon: Icons.print,
                  onPressed: onPrint!,
                  isOutlined: true,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
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
