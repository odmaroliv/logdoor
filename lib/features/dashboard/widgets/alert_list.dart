// lib/features/dashboard/widgets/alert_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/alert.dart';

class AlertList extends StatelessWidget {
  final List<Alert> alerts;
  final Function(Alert)? onResolve;
  final Function(Alert)? onViewDetails;

  const AlertList({
    Key? key,
    required this.alerts,
    this.onResolve,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay alertas activas'),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: alerts.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return _buildAlertItem(context, alerts[index]);
        },
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, Alert alert) {
    final formatter = DateFormat('dd/MM HH:mm');
    final formattedTime = formatter.format(alert.timestamp);

    // Determinar el icono y color basado en el tipo de alerta
    IconData alertIcon;
    Color alertColor;

    switch (alert.alertType) {
      case 'panic':
        alertIcon = Icons.emergency;
        alertColor = Colors.red;
        break;
      case 'security':
        alertIcon = Icons.security;
        alertColor = Colors.orange;
        break;
      case 'maintenance':
        alertIcon = Icons.build;
        alertColor = Colors.amber;
        break;
      default:
        alertIcon = Icons.notifications_active;
        alertColor = Colors.red;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: alertColor.withOpacity(0.2),
        child: Icon(
          alertIcon,
          color: alertColor,
        ),
      ),
      title: Text(
        _getAlertTitle(alert.alertType),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reportada por: ${alert.userName}'),
          Text('Hora: $formattedTime'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onResolve != null)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Resolver',
              onPressed: () => onResolve!(alert),
            ),
          if (onViewDetails != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'Ver detalles',
              onPressed: () => onViewDetails!(alert),
            ),
        ],
      ),
      onTap: onViewDetails != null ? () => onViewDetails!(alert) : null,
      isThreeLine: true,
    );
  }

  String _getAlertTitle(String alertType) {
    switch (alertType) {
      case 'panic':
        return 'Alerta de Pánico';
      case 'security':
        return 'Alerta de Seguridad';
      case 'maintenance':
        return 'Alerta de Mantenimiento';
      default:
        return 'Alerta';
    }
  }
}
