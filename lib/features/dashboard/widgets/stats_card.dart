import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtén el ancho de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;

    // Definir el tamaño de los iconos dependiendo del ancho de la pantalla
    double iconSize = screenWidth < 400
        ? 14
        : 20; // iconos más pequeños en pantallas pequeñas

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono con fondo circular
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              const SizedBox(height: 12),

              // Valor principal con tamaño dinámico
              Expanded(
                // Utilizamos Expanded para que ocupe el espacio restante sin desbordar
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth < 400
                            ? 16
                            : 20, // Ajusta el tamaño de texto
                      ),
                  overflow: TextOverflow
                      .ellipsis, // Si el texto es largo, lo truncamos
                  maxLines: 1, // Evita que el texto ocupe más de una línea
                ),
              ),

              // Título con estilo más pequeño
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: screenWidth < 400
                          ? 14
                          : 16, // Ajusta el tamaño de texto
                    ),
                overflow: TextOverflow.ellipsis, // Trunca si es necesario
                maxLines: 1, // Limita a una línea
              ),
            ],
          ),
        ),
      ),
    );
  }
}
