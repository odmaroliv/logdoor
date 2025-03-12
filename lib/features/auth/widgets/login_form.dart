import 'package:flutter/material.dart';
import 'package:logdoor/core/utils/exceptions.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../providers/auth_provider.dart';
import 'biometric_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          FormBuilderTextField(
            name: 'email',
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'nombre@ejemplo.com',
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

          // Password field
          FormBuilderTextField(
            name: 'password',
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                  errorText: 'La contraseña debe tener al menos 6 caracteres'),
            ]),
          ),
          const SizedBox(height: 8),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Implementar lógica de recuperación de contraseña
              },
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 16),

          // Error message
          if (authProvider.error != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                authProvider.error!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          const SizedBox(height: 16),

          // Login button
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submitForm(authProvider),
            child: _isSubmitting
                ? const CircularProgressIndicator()
                : const Text('Iniciar sesión'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Biometric login button
          const BiometricButton(),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes una cuenta?'),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/register');
                },
                child: const Text('Regístrate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm(AuthProvider authProvider) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      final formData = _formKey.currentState!.value;
      final email = formData['email'] as String;
      final password = formData['password'] as String;

      try {
        final success = await authProvider.login(email, password);

        if (mounted) {
          if (success) {
            // Si el login fue exitoso y MFA no es requerido, navegar al dashboard
            if (!authProvider.requiresMfa) {
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
                  Navigator.of(context).pushReplacementNamed('/access/list');
                }
              }
            } else {
              // Si MFA es requerido, redirigir a la pantalla MFA
              Navigator.of(context).pushNamed(
                '/mfa',
                arguments: {
                  'email': email,
                  'password': password,
                  // Aquí pasas el mfaId al capturar la excepción
                  'otpId': authProvider
                      .mfaId, // Esto debe estar en authProvider después de la autenticación inicial
                },
              );
            }
          }
        }
      } catch (e) {
        if (e is MfaRequiredException) {
          // Aquí manejas el error MFA si no fue capturado antes
          print("MFA ID: " + e.mfaId);
          Navigator.of(context).pushNamed(
            '/mfa',
            arguments: {
              'email': email,
              'password': password,
              'otpId': e.mfaId, // Aquí pasas el mfaId desde la excepción
            },
          );
        } else {
          // Manejar otros errores
          setState(() {
            // _error = e.toString(); // Si quieres mostrar el error
          });
        }
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
