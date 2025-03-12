import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:logdoor/core/services/qr_service.dart';
import 'package:logdoor/core/utils/logger.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/access_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  //bool _torchEnabled = false;
  final QRService _qrService = QRService();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Access QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_off),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: (BarcodeCapture capture) async {
              if (_isProcessing) return;

              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                setState(() {
                  _isProcessing = true;
                });

                final accessProvider =
                    Provider.of<AccessProvider>(context, listen: false);
                await _processQrCode(barcode.rawValue!, accessProvider);
              }
            },
          ),

          // Scan overlay
          CustomPaint(
            painter: ScannerOverlayPainter(
              borderColor: Theme.of(context).primaryColor,
              borderRadius: 10.0,
              borderLength: 30.0,
              borderWidth: 10.0,
            ),
            child: Container(),
          ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: LoadingIndicator(text: 'Verifying Access...'),
              ),
            ),

          // Instructions
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Aim the camera at the QR code to verify access',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQrCode(
      String qrContent, AccessProvider accessProvider) async {
    try {
      Logger.info(
          'Procesando código QR: ${qrContent.substring(0, math.min(20, qrContent.length))}...');

      // Intentar decodificar el QR (maneja tanto QRs normales como seguros)
      final decodedData = await _qrService.verifyAndDecodeQR(qrContent);

      if (decodedData == null) {
        if (mounted) {
          _showAccessResult(
            title: 'QR Inválido',
            message: 'Este código QR no es válido o ha sido manipulado.',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
        return;
      }

      // Obtener el código de acceso del QR decodificado
      String accessCode;

      // Si es un QR seguro
      if (decodedData.containsKey('accessCode')) {
        accessCode = decodedData['accessCode'];
      } else {
        // QR simple
        accessCode = qrContent;
      }

      Logger.info('Verificando código de acceso: $accessCode');

      // Verificar en la base de datos
      final isValid = await accessProvider.verifyAccessCode(accessCode);

      if (mounted) {
        if (isValid) {
          // Access valid - show success and option to proceed to inspection
          _showAccessResult(
            title: 'Acceso Verificado',
            message: 'Código QR válido. ¿Desea proceder con la inspección?',
            icon: Icons.check_circle,
            iconColor: Colors.green,
            onConfirm: () {
              Navigator.of(context).pushReplacementNamed(
                '/inspection/new',
                arguments: {'accessCode': accessCode},
              );
            },
          );
        } else {
          // Access invalid
          _showAccessResult(
            title: 'Acceso Inválido',
            message: 'Este código QR no es válido o ha expirado.',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      Logger.error('Error al procesar QR', error: e);

      if (mounted) {
        _showAccessResult(
          title: 'Error',
          message: 'No se pudo verificar el código QR. ${e.toString()}',
          icon: Icons.warning,
          iconColor: Colors.orange,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showAccessResult({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              if (onConfirm == null) {
                // Resume scanning
                setState(() {
                  _isProcessing = false;
                });
              }
            },
            child: Text(onConfirm == null ? 'OK' : 'Cancel'),
          ),
          if (onConfirm != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('Proceed'),
            ),
        ],
      ),
    );
  }
}

// Custom painter para el marco de escaneo
class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    this.cutOutSize = 300,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final double cutOutWidth = cutOutSize;
    final double cutOutHeight = cutOutSize;

    final Rect cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cutOutWidth,
      height: cutOutHeight,
    );

    // Dibuja el fondo semitransparente
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              cutOutRect, Radius.circular(borderRadius))),
      ),
      Paint()..color = Colors.black54,
    );

    // Dibuja las esquinas del marco
    // Esquina superior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left, cutOutRect.top + borderRadius + borderLength)
        ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius)
        ..arcToPoint(
          Offset(cutOutRect.left + borderRadius, cutOutRect.top),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutRect.left + borderRadius + borderLength, cutOutRect.top),
      paint,
    );

    // Esquina superior derecha
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderRadius - borderLength, cutOutRect.top)
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
        ..arcToPoint(
          Offset(cutOutRect.right, cutOutRect.top + borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(
            cutOutRect.right, cutOutRect.top + borderRadius + borderLength),
      paint,
    );

    // Esquina inferior derecha
    canvas.drawPath(
      Path()
        ..moveTo(
            cutOutRect.right, cutOutRect.bottom - borderRadius - borderLength)
        ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius)
        ..arcToPoint(
          Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(
            cutOutRect.right - borderRadius - borderLength, cutOutRect.bottom),
      paint,
    );

    // Esquina inferior izquierda
    canvas.drawPath(
      Path()
        ..moveTo(
            cutOutRect.left + borderRadius + borderLength, cutOutRect.bottom)
        ..lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
        ..arcToPoint(
          Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(
            cutOutRect.left, cutOutRect.bottom - borderRadius - borderLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.borderLength != borderLength ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.cutOutSize != cutOutSize;
}
