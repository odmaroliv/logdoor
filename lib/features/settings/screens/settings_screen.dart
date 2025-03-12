// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/settings_tile.dart';
import '../providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../config/localization.dart';
import '../../../core/utils/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: settingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Sección de Perfil
                _buildSectionHeader(context, 'Perfil y Cuenta'),
                SettingsTile(
                  leadingIcon: Icons.person,
                  title: 'Información de Perfil',
                  subtitle: user?.name ?? 'Cargando...',
                  onTap: () => _navigateToProfileScreen(context),
                ),
                SettingsTile(
                  leadingIcon: Icons.password,
                  title: 'Cambiar Contraseña',
                  onTap: () => _showChangePasswordDialog(context),
                ),

                // Sección de Apariencia
                _buildSectionHeader(context, 'Apariencia'),
                SettingsTile(
                  leadingIcon: Icons.dark_mode,
                  title: 'Modo Oscuro',
                  trailing: Switch(
                    value: settingsProvider.isDarkMode,
                    onChanged: (value) {
                      settingsProvider.toggleDarkMode();
                    },
                  ),
                  showDivider: false,
                ),

                // Sección de Idioma
                _buildSectionHeader(context, 'Idioma'),
                SettingsTile(
                  leadingIcon: Icons.language,
                  title: 'Idioma de la aplicación',
                  subtitle: _getLanguageName(context),
                  onTap: () => _showLanguageDialog(context),
                ),

                // Sección de Seguridad
                _buildSectionHeader(context, 'Seguridad'),
                SettingsTile(
                  leadingIcon: Icons.fingerprint,
                  title: 'Autenticación biométrica',
                  subtitle: settingsProvider.isBiometricsEnabled
                      ? 'Habilitada'
                      : 'Deshabilitada',
                  trailing: Switch(
                    value: settingsProvider.isBiometricsEnabled,
                    onChanged: (value) {
                      _toggleBiometrics(context);
                    },
                  ),
                ),

                // Almacenes (Solo para administradores)
                if (user?.isAdmin == true) ...[
                  _buildSectionHeader(context, 'Administración'),
                  SettingsTile(
                    leadingIcon: Icons.warehouse,
                    title: 'Gestión de Almacenes',
                    subtitle:
                        '${settingsProvider.warehouses.length} almacenes disponibles',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/settings/warehouses'),
                  ),
                ],

                // Sección Acerca de
                _buildSectionHeader(context, 'Acerca de'),
                SettingsTile(
                  leadingIcon: Icons.info,
                  title: 'Información de la aplicación',
                  subtitle: 'Logdoor v1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),

                // Cerrar sesión
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _confirmLogout(context),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  // Método para obtener el nombre del idioma actual
  String _getLanguageName(BuildContext context) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final languageCode = settingsProvider.appLocale.languageCode;
    return LocalizationService.getLanguageName(languageCode);
  }

  // Método para mostrar el diálogo de selección de idioma
  void _showLanguageDialog(BuildContext context) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar idioma'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Español'),
                trailing: settingsProvider.appLocale.languageCode == 'es'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  settingsProvider.changeLanguage('es');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('English'),
                trailing: settingsProvider.appLocale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  settingsProvider.changeLanguage('en');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Método para mostrar el diálogo de cambio de contraseña
  void _showChangePasswordDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    bool _obscureCurrentPassword = true;
    bool _obscureNewPassword = true;
    bool _obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cambiar Contraseña'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrentPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureCurrentPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su contraseña actual';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureNewPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese una nueva contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar nueva contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme su nueva contraseña';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      Navigator.of(context).pop();

                      // Mostrar indicador de carga
                      _showLoadingDialog(context, 'Actualizando contraseña...');

                      try {
                        final settingsProvider = Provider.of<SettingsProvider>(
                            context,
                            listen: false);
                        final success = await settingsProvider.updatePassword(
                          currentPassword: _currentPasswordController.text,
                          newPassword: _newPasswordController.text,
                        );

                        // Cerrar diálogo de carga
                        Navigator.of(context).pop();
                        if (success) {
                          _showSuccessDialog(
                              context, 'Contraseña actualizada con éxito');
                        } else {
                          _showErrorDialog(
                              context, 'No se pudo actualizar la contraseña');
                        }
                      } catch (e) {
                        // Cerrar diálogo de carga
                        Navigator.of(context).pop();
                        _showErrorDialog(context, 'Error: ${e.toString()}');
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Método para activar/desactivar biometría
  void _toggleBiometrics(BuildContext context) {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    // Si ya está habilitada, deshabilitarla
    if (settingsProvider.isBiometricsEnabled) {
      _confirmDisableBiometrics(context);
    } else {
      // Si no está habilitada, mostrar diálogo para habilitar
      _showEnableBiometricsDialog(context);
    }
  }

  // Diálogo para habilitar biometría
  void _showEnableBiometricsDialog(BuildContext context) {
    final _passwordController = TextEditingController();
    bool _obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Habilitar autenticación biométrica'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Para habilitar la autenticación biométrica, confirme su contraseña:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();

                    // Mostrar indicador de carga
                    _showLoadingDialog(context, 'Habilitando biometría...');

                    try {
                      final settingsProvider =
                          Provider.of<SettingsProvider>(context, listen: false);
                      final success = await settingsProvider.toggleBiometrics(
                        _passwordController.text,
                      );

                      // Cerrar diálogo de carga
                      Navigator.of(context).pop();

                      if (success) {
                        _showSuccessDialog(context,
                            'Autenticación biométrica habilitada con éxito');
                      } else {
                        _showErrorDialog(context,
                            'No se pudo habilitar la autenticación biométrica');
                      }
                    } catch (e) {
                      // Cerrar diálogo de carga
                      Navigator.of(context).pop();
                      _showErrorDialog(context, 'Error: ${e.toString()}');
                    }
                  },
                  child: const Text('Habilitar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Diálogo para confirmar deshabilitación de biometría
  void _confirmDisableBiometrics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deshabilitar biometría'),
          content: const Text(
            '¿Está seguro de que desea deshabilitar la autenticación biométrica?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Mostrar indicador de carga
                _showLoadingDialog(context, 'Deshabilitando biometría...');

                try {
                  final settingsProvider =
                      Provider.of<SettingsProvider>(context, listen: false);
                  // Pasamos una contraseña vacía porque no se necesita para deshabilitar
                  final success = await settingsProvider.toggleBiometrics('');

                  // Cerrar diálogo de carga
                  Navigator.of(context).pop();

                  if (success) {
                    _showSuccessDialog(context,
                        'Autenticación biométrica deshabilitada con éxito');
                  } else {
                    _showErrorDialog(context,
                        'No se pudo deshabilitar la autenticación biométrica');
                  }
                } catch (e) {
                  // Cerrar diálogo de carga
                  Navigator.of(context).pop();
                  _showErrorDialog(context, 'Error: ${e.toString()}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deshabilitar'),
            ),
          ],
        );
      },
    );
  }

  // Navegar a la pantalla de perfil
  void _navigateToProfileScreen(BuildContext context) {
    Navigator.of(context).pushNamed('/settings/profile');
  }

  // Mostrar diálogo "Acerca de"
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AboutDialog(
          applicationName: 'Logdoor',
          applicationVersion: 'v1.0.0',
          applicationIcon: Image.asset(
            'assets/images/logo_small.png',
            width: 48,
            height: 48,
          ),
          applicationLegalese: '© 2025 Logdoor. Todos los derechos reservados.',
          children: [
            const SizedBox(height: 16),
            const Text(
              'Logdoor es una aplicación móvil para el control de accesos e inspecciones en cumplimiento con los lineamientos CTPAT.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        );
      },
    );
  }

  // Confirmar cerrar sesión
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Está seguro de que desea cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                authProvider.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo de carga
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  // Diálogo de éxito
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Éxito'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'inspector':
        return 'Inspector';
      case 'guard':
        return 'Guardia';
      case 'visitor':
        return 'Visitante';
      default:
        return role;
    }
  }

  // Diálogo de error
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
