// lib/features/dashboard/widgets/recent_activity.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentActivity extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final int maxItems;

  const RecentActivity({
    Key? key,
    required this.activities,
    this.maxItems = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay actividad reciente'),
          ),
        ),
      );
    }

    // Mostrar solo el número máximo de elementos
    final displayedActivities = activities.length > maxItems
        ? activities.sublist(0, maxItems)
        : activities;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayedActivities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = displayedActivities[index];
          return _buildActivityItem(context, activity);
        },
      ),
    );
  }

  Widget _buildActivityItem(
      BuildContext context, Map<String, dynamic> activity) {
    final formatter = DateFormat('dd/MM HH:mm');
    final timestamp = activity['timestamp'] as DateTime;
    final formattedTime = formatter.format(timestamp);

    // Configurar icono y color basado en el tipo de actividad
    IconData activityIcon;
    Color iconColor;

    switch (activity['type']) {
      case 'access':
        if (activity['subtype'] == 'entry') {
          activityIcon = Icons.login;
          iconColor = Colors.green;
        } else {
          activityIcon = Icons.logout;
          iconColor = Colors.blue;
        }
        break;
      case 'inspection':
        if (activity['subtype'] == 'issues') {
          activityIcon = Icons.warning;
          iconColor = Colors.orange;
        } else {
          activityIcon = Icons.check_circle;
          iconColor = Colors.green;
        }
        break;
      case 'alert':
        activityIcon = Icons.notifications_active;
        iconColor = Colors.red;
        break;
      default:
        activityIcon = Icons.event_note;
        iconColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2),
        child: Icon(
          activityIcon,
          color: iconColor,
        ),
      ),
      title: Text(activity['title']),
      subtitle: Text(activity['description']),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      onTap: () {
        // Aquí se podría implementar la navegación a los detalles
        // basados en el tipo de actividad y sus datos
        if (activity['data'] != null) {
          switch (activity['type']) {
            case 'access':
              // Navegar a detalles de acceso
              break;
            case 'inspection':
              // Navegar a detalles de inspección
              break;
            case 'alert':
              // Navegar a detalles de alerta
              break;
          }
        }
      },
    );
  }
}
