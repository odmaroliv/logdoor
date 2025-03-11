import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/access_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessProvider = Provider.of<AccessProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Access QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _scannerController.switchCamera(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
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

                await _processQrCode(barcode.rawValue!, accessProvider);
              }
            },
          ),

          // Scan overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Theme.of(context).primaryColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
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
      String code, AccessProvider accessProvider) async {
    try {
      final isValid = await accessProvider.verifyAccessCode(code);

      if (mounted) {
        if (isValid) {
          // Access valid - show success and option to proceed to inspection
          _showAccessResult(
            title: 'Access Verified',
            message:
                'QR code is valid. Would you like to proceed with inspection?',
            icon: Icons.check_circle,
            iconColor: Colors.green,
            onConfirm: () {
              Navigator.of(context).pushReplacementNamed(
                '/inspection/new',
                arguments: {'accessCode': code},
              );
            },
          );
        } else {
          // Access invalid
          _showAccessResult(
            title: 'Invalid Access',
            message: 'This QR code is not valid or has expired.',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showAccessResult(
          title: 'Error',
          message: 'Could not verify the QR code. ${e.toString()}',
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
