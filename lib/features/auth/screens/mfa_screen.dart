// lib/features/auth/screens/mfa_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../providers/auth_provider.dart';
import 'dart:async'; // Importar Timer

class MfaScreen extends StatefulWidget {
  final String email;
  final String password;
  final String otpId;

  const MfaScreen({
    Key? key,
    required this.email,
    required this.password,
    required this.otpId,
  }) : super(key: key);

  @override
  State<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;
  int _remainingSeconds = 30;
  bool _canResend = false;
  Timer? _timer; // Agregar el timer

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  // Cambiar _startResendTimer a usar Timer.periodic
  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _remainingSeconds = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          setState(() {
            _canResend = true;
          });
          _timer?.cancel(); // Detener el temporizador una vez que llegue a 0
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.shield,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              'Verificación de dos pasos',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hemos enviado un código de verificación a ${widget.email}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Campo de código
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PinCodeTextField(
                appContext: context,
                length: 8,
                controller: _codeController,
                autoFocus: true,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 50,
                  fieldWidth: 35,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.grey[100],
                  activeColor: Theme.of(context).primaryColor,
                  inactiveColor: Colors.grey,
                  selectedColor: Theme.of(context).primaryColor,
                ),
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                onCompleted: (value) {
                  _verifyCode();
                },
                onChanged: (value) {
                  setState(() {
                    _error = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Mostrar error
            if (_error != null || authProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error ?? authProvider.error ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),

            // Botón de verificar
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isVerifying
                  ? const CircularProgressIndicator()
                  : const Text('Verificar'),
            ),
            const SizedBox(height: 16),

            // Botón de reenviar código
            TextButton(
              onPressed: (!_canResend || _isResending) ? null : _resendCode,
              child: _isResending
                  ? const CircularProgressIndicator()
                  : Text(_canResend
                      ? 'Reenviar código'
                      : 'Reenviar código en $_remainingSeconds segundos'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 8) {
      setState(() {
        _error = 'Por favor ingrese un código de 6 dígitos';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success =
          await authProvider.verifyMFA(widget.otpId, _codeController.text);

      if (success && mounted) {
        // Navegar al dashboard según el rol
        final user = authProvider.currentUser;
        if (user != null) {
          if (user.isAdmin) {
            Navigator.of(context).pushReplacementNamed('/dashboard/admin');
          } else if (user.isInspector) {
            Navigator.of(context).pushReplacementNamed('/dashboard/inspector');
          } else if (user.isGuard) {
            Navigator.of(context).pushReplacementNamed('/dashboard/guard');
          } else {
            Navigator.of(context).pushReplacementNamed('/access/list');
          }
        }
      } else if (mounted) {
        setState(() {
          _error = 'Código inválido. Inténtelo de nuevo.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de verificación: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      // Llamar al método resendOtp de AuthProvider para reenviar el código
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.resendOtp(widget.email); // Ahora utilizamos el método

      if (mounted) {
        setState(() {
          _isResending = false;
        });
        _startResendTimer(); // Reinicia el temporizador después de reenviar el código
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código reenviado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _error = 'Error al reenviar código: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer
        ?.cancel(); // Asegúrate de cancelar el temporizador cuando se dispose el widget
    super.dispose();
  }
}
