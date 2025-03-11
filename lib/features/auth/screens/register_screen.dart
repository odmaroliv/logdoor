// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../../core/services/user_service.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final UserService _userService = UserService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Crear nueva cuenta',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa tus datos para crear una cuenta',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),

            // Formulario de registro
            FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nombre completo
                  FormBuilderTextField(
                    name: 'name',
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'El nombre es obligatorio'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  FormBuilderTextField(
                    name: 'email',
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'El correo es obligatorio'),
                      FormBuilderValidators.email(
                          errorText: 'Ingrese un correo válido'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Teléfono
                  FormBuilderTextField(
                    name: 'phoneNumber',
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'El teléfono es obligatorio'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Rol (deshabilitado para usuarios normales, solo para admin)
                  FormBuilderDropdown<String>(
                    name: 'role',
                    decoration: const InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'visitor',
                        child: Text('Visitante'),
                      ),
                      // En una implementación real, solo el admin podría crear otros roles
                    ],
                    initialValue: 'visitor',
                    enabled: false, // Deshabilitar para usuarios normales
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  FormBuilderTextField(
                    name: 'password',
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'La contraseña es obligatoria'),
                      FormBuilderValidators.minLength(6,
                          errorText:
                              'La contraseña debe tener al menos 6 caracteres'),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Confirmar contraseña
                  FormBuilderTextField(
                    name: 'passwordConfirm',
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Confirme su contraseña'),
                      (val) {
                        if (val !=
                            _formKey.currentState?.fields['password']?.value) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Mensaje de error
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Botón de registro
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Registrarse'),
                  ),
                  const SizedBox(height: 16),

                  // Link para volver al login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Ya tienes una cuenta?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Inicia sesión'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSubmitting = true;
        _error = null;
      });

      try {
        final formData = _formKey.currentState!.value;

        // Crear usuario
        await _userService.createUser(
          name: formData['name'],
          email: formData['email'],
          password: formData['password'],
          role: formData['role'],
          phoneNumber: formData['phoneNumber'],
        );

        // Iniciar sesión automáticamente
        if (mounted) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final success = await authProvider.login(
            formData['email'],
            formData['password'],
          );

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registro exitoso')),
            );
            Navigator.of(context).pushReplacementNamed('/login');
          } else if (mounted) {
            setState(() {
              _error = 'Registro exitoso. Por favor inicia sesión';
            });
          }
        }
      } catch (e) {
        setState(() {
          _error = 'Error al registrar: ${e.toString()}';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }
}
