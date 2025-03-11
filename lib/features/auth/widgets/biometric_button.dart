// lib/features/auth/widgets/biometric_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/logger.dart';

class BiometricButton extends StatelessWidget {
  const BiometricButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return FutureBuilder<bool>(
      future: authProvider.isBiometricsEnabled(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 50);
        }

        // No mostrar botón si biometría no está disponible/habilitada
        if (!snapshot.hasData || snapshot.data == false) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.fingerprint),
              label: const Text('Iniciar con Huella'),
              onPressed: () async {
                try {
                  final success =
                      await authProvider.authenticateWithBiometrics();
                  if (success && context.mounted) {
                    // Navegar al dashboard según el rol
                    final user = authProvider.currentUser;
                    if (user != null) {
                      if (user.isAdmin) {
                        Navigator.of(context)
                            .pushReplacementNamed('/dashboard/admin');
                      } else if (user.isInspector) {
                        Navigator.of(context)
                            .pushReplacementNamed('/dashboard/inspector');
                      } else if (user.isGuard) {
                        Navigator.of(context)
                            .pushReplacementNamed('/dashboard/guard');
                      } else {
                        Navigator.of(context)
                            .pushReplacementNamed('/access/list');
                      }
                    }
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Error de autenticación biométrica')),
                    );
                  }
                } catch (e) {
                  Logger.error('Error en autenticación biométrica', error: e);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
        );
      },
    );
  }
}
