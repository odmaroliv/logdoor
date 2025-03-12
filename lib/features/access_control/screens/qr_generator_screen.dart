// lib/features/access_control/screens/qr_generator_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/access.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/access_provider.dart';
import '../../../core/services/qr_service.dart';

class QrGeneratorScreen extends StatefulWidget {
  final Access access;

  const QrGeneratorScreen({Key? key, required this.access}) : super(key: key);

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final QRService _qrService = QRService();
  String _qrData = '';
  bool _isLoading = true;
  bool _isSecureMode = true; // Por defecto usar modo seguro

  @override
  void initState() {
    super.initState();
    _generateQrData();
  }

  Future<void> _generateQrData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSecureMode) {
        // Generar QR encriptado
        _qrData = await _qrService.generateSecureQRCode(widget.access);
      } else {
        // Usar el código de acceso simple
        _qrData = widget.access.accessCode;
      }
    } catch (e) {
      // En caso de error, usar el código simple
      _qrData = widget.access.accessCode;
      _isSecureMode = false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSecurityMode() {
    setState(() {
      _isSecureMode = !_isSecureMode;
    });
    _generateQrData();
  }

  void _shareQRCode() {
    Share.share(
      'Código de acceso: ${widget.access.accessCode}\nFecha: ${widget.access.formattedTimestamp}\nAlmacén: ${widget.access.warehouseName}',
      subject: 'Código de acceso Logdoor',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Código QR de Acceso'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Información del acceso
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Información de Acceso',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text('Conductor: ${widget.access.userName}'),
                    Text('Almacén: ${widget.access.warehouseName}'),
                    if (widget.access.vehicleData != null &&
                        widget.access.vehicleData!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Información del Vehículo',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                          'Placa: ${widget.access.vehicleData!['plate'] ?? 'N/A'}'),
                      Text(
                          'Tipo: ${widget.access.vehicleData!['type'] ?? 'N/A'}'),
                    ],
                    const SizedBox(height: 8),
                    Text(
                        'Tipo de Acceso: ${widget.access.accessType == 'entry' ? 'Entrada' : 'Salida'}'),
                    Text('Hora: ${widget.access.formattedTimestamp}'),
                    if (!widget.access.isSync) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.sync_problem,
                                color: Colors.amber.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Este acceso fue creado sin conexión y se sincronizará cuando haya conexión a internet.',
                                style: TextStyle(color: Colors.amber.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Indicador de modo seguro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Modo estándar'),
                Switch(
                  value: _isSecureMode,
                  onChanged: (value) => _toggleSecurityMode(),
                ),
                const Text('Modo seguro'),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showSecurityInfoDialog(context),
                ),
              ],
            ),
          ),

          // QR Code
          _isLoading
              ? const CircularProgressIndicator()
              : Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                    data: _qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    embeddedImage:
                        const AssetImage('assets/images/logo_small.png'),
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(40, 40),
                    ),
                  ),
                ),

          const SizedBox(height: 24),
          Text(
            'Código de Acceso',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            widget.access.accessCode,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
          ),

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Compartir',
                    icon: Icons.share,
                    onPressed: _shareQRCode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Imprimir',
                    icon: Icons.print,
                    onPressed: () {
                      // Funcionalidad de impresión (opcional)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función de impresión no implementada'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Seguridad'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modos de QR disponibles:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
                '• Modo estándar: Utiliza un código simple. Compatible con todas las versiones.'),
            SizedBox(height: 8),
            Text(
                '• Modo seguro: El código QR está encriptado y firmado digitalmente para prevenir falsificaciones. Recomendado para mayor seguridad.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
