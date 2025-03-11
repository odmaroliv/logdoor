import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/models/access.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/access_provider.dart';

class QrGeneratorScreen extends StatelessWidget {
  final Access access;

  const QrGeneratorScreen({Key? key, required this.access}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access QR Code'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Access information
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Access Information',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text('Driver: ${access.userName}'),
                    Text('Warehouse: ${access.warehouseName}'),
                    if (access.vehicleData != null &&
                        access.vehicleData!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Vehicle Information',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Plate: ${access.vehicleData!['plate'] ?? 'N/A'}'),
                      Text('Type: ${access.vehicleData!['type'] ?? 'N/A'}'),
                    ],
                    const SizedBox(height: 8),
                    Text(
                        'Access Type: ${access.accessType == 'entry' ? 'Entry' : 'Exit'}'),
                    Text('Time: ${access.formattedTimestamp}'),
                    if (!access.isSync) ...[
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
                                'This access was created offline and will be synchronized when internet connection is available.',
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

          // QR Code
          Container(
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
              data: access.accessCode,
              version: QrVersions.auto,
              size: 200.0,
              embeddedImage: const AssetImage('assets/images/logo_small.png'),
              embeddedImageStyle: QrEmbeddedImageStyle(
                size: const Size(40, 40),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Access Code',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            access.accessCode,
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
                    text: 'Share',
                    icon: Icons.share,
                    onPressed: () {
                      // Share QR code
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Print',
                    icon: Icons.print,
                    onPressed: () {
                      // Print QR code
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
}
