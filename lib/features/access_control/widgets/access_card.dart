// lib/features/access_control/widgets/access_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/access.dart';

class AccessCard extends StatelessWidget {
  final Access access;
  final VoidCallback? onTap;
  final VoidCallback? onQrTap;

  const AccessCard({
    Key? key,
    required this.access,
    this.onTap,
    this.onQrTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono de entrada/salida
                  CircleAvatar(
                    backgroundColor: access.accessType == 'entry'
                        ? Colors.green
                        : Colors.blue,
                    child: Icon(
                      access.accessType == 'entry' ? Icons.login : Icons.logout,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Información principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          access.accessType == 'entry' ? 'Entrada' : 'Salida',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          formatter.format(access.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Botón de QR
                  if (onQrTap != null)
                    IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: onQrTap,
                      tooltip: 'Ver código QR',
                    ),
                ],
              ),

              const Divider(height: 24),

              // Detalles del acceso
              _buildDetailRow(
                  'Conductor', access.vehicleData?['driver'] ?? 'N/A'),
              _buildDetailRow('Placa', access.vehicleData?['plate'] ?? 'N/A'),
              _buildDetailRow('Almacén', access.warehouseName),

              // Indicador de sincronización
              if (!access.isSync)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
