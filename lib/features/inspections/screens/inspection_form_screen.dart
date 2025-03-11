import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:logdoor/features/access_control/providers/access_provider.dart';
import 'package:logdoor/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/access.dart';
import '../../../core/services/inspection_service.dart';
import '../../../core/services/geolocation_service.dart';
import '../widgets/checklist_item.dart';
import '../widgets/photo_capture.dart';
import '../widgets/signature_pad.dart';
import '../providers/inspection_provider.dart';

class InspectionFormScreen extends StatefulWidget {
  final String? accessCode;

  const InspectionFormScreen({Key? key, this.accessCode}) : super(key: key);

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _imagePicker = ImagePicker();
  List<XFile> _photos = [];
  String? _signatureImagePath;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Access? _access;

  // Define CTPAT checklist items
  final List<Map<String, dynamic>> _checklistItems = [
    {
      'title': 'Front Bumper/Defense',
      'description': 'Check for damage, modifications, or hidden compartments',
      'key': 'front_bumper'
    },
    {
      'title': 'Engine Compartment',
      'description':
          'Inspect for suspicious wiring, packages, or modifications',
      'key': 'engine'
    },
    {
      'title': 'Tires and Rims',
      'description': 'Check for damage, unusual wear, or hidden compartments',
      'key': 'tires'
    },
    {
      'title': 'Fuel Tank',
      'description': 'Inspect for alterations or anomalies',
      'key': 'fuel_tank'
    },
    {
      'title': 'Cabin Interior',
      'description': 'Check for unauthorized items or modifications',
      'key': 'cabin'
    },
    {
      'title': 'Cargo Area',
      'description': 'Verify seals, check for unauthorized access',
      'key': 'cargo'
    },
    {
      'title': 'Undercarriage',
      'description': 'Inspect for hidden compartments or modifications',
      'key': 'undercarriage'
    },
    {
      'title': 'Roof',
      'description': 'Check for unauthorized access or modifications',
      'key': 'roof'
    },
    {
      'title': 'Doors and Locks',
      'description': 'Verify proper functioning and no tampering',
      'key': 'doors'
    },
    {
      'title': 'Refrigeration Unit',
      'description': 'Check for proper function and tampering',
      'key': 'refrigeration'
    },
    {
      'title': 'Fifth Wheel',
      'description': 'Inspect for modifications or hidden compartments',
      'key': 'fifth_wheel'
    },
    {
      'title': 'External/Internal Compartments',
      'description': 'Check all compartments for unauthorized items',
      'key': 'compartments'
    },
    {
      'title': 'Floor (Inside)',
      'description': 'Inspect for unusual thickness, repairs, or modifications',
      'key': 'floor'
    },
    {
      'title': 'Ceiling/Roof (Inside)',
      'description': 'Check for tampering or modifications',
      'key': 'ceiling'
    },
    {
      'title': 'Right Side Wall',
      'description': 'Inspect for unusual modifications or hollow areas',
      'key': 'right_wall'
    },
    {
      'title': 'Left Side Wall',
      'description': 'Inspect for unusual modifications or hollow areas',
      'key': 'left_wall'
    },
    {
      'title': 'Front Wall',
      'description': 'Check for tampering or modifications',
      'key': 'front_wall'
    },
    {
      'title': 'Security Seals',
      'description': 'Verify all seals are intact and match documentation',
      'key': 'seals'
    },
  ];

  @override
  void initState() {
    super.initState();

    if (widget.accessCode != null) {
      _loadAccessData();
    }
  }

  Future<void> _loadAccessData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accessProvider =
          Provider.of<AccessProvider>(context, listen: false);
      final access = await accessProvider.getAccessByCode(widget.accessCode!);

      setState(() {
        _access = access;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading access data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspectionProvider = Provider.of<InspectionProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('CTPAT Inspection')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_access == null && widget.accessCode != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CTPAT Inspection')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Access data not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CTPAT Inspection'),
      ),
      body: FormBuilder(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Access information (if available)
              if (_access != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Access Information',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Driver: ${_access!.userName}'),
                        Text(
                            'Vehicle: ${_access!.vehicleData?['plate'] ?? 'N/A'}'),
                        Text('Warehouse: ${_access!.warehouseName}'),
                        Text('Time: ${_access!.formattedTimestamp}'),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              Text(
                'CTPAT Inspection Checklist',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),
              Text(
                'Complete all items below. Each item requires a status (Bien/Mal/Revisar) and at least one photo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),

              const SizedBox(height: 16),

              // Checklist items
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _checklistItems.length,
                itemBuilder: (context, index) {
                  final item = _checklistItems[index];

                  return ChecklistItem(
                    title: item['title'],
                    description: item['description'],
                    formField: 'checklist.${item['key']}',
                    onPhotoTaken: (XFile photo) {
                      setState(() {
                        _photos.add(photo);
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              Text('Additional Notes',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FormBuilderTextField(
                name: 'notes',
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter any additional observations or notes',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              Text('Digital Signature',
                  style: Theme.of(context).textTheme.titleMedium),
              const Text('Please sign below to complete the inspection'),
              const SizedBox(height: 8),
              SignaturePad(
                onSigned: (String path) {
                  setState(() {
                    _signatureImagePath = path;
                  });
                },
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitInspection(inspectionProvider),
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Submit Inspection'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitInspection(InspectionProvider provider) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      // Validate that all checklist items have been completed
      final formData = _formKey.currentState!.value;
      final checklist = formData['checklist'] as Map<String, dynamic>?;

      if (checklist == null || checklist.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete the checklist')),
        );
        return;
      }

      // Check that all items have a status
      bool allItemsHaveStatus = true;
      for (var item in _checklistItems) {
        final key = item['key'];
        final itemData = checklist[key] as Map<String, dynamic>?;

        if (itemData == null ||
            itemData['status'] == null ||
            itemData['status'].isEmpty) {
          allItemsHaveStatus = false;
          break;
        }
      }

      if (!allItemsHaveStatus) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please provide a status for all checklist items')),
        );
        return;
      }

      if (_photos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please take at least one photo')),
        );
        return;
      }

      if (_signatureImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign the inspection form')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final geolocation = await GeolocationService().getCurrentLocation();

        // Create inspection data
        final inspectionData = {
          'access': _access?.id ?? 'manual_inspection',
          'inspector': authProvider.currentUser!.id,
          'inspectorName': authProvider.currentUser!.name,
          'checklist': formData['checklist'],
          'notes': formData['notes'],
          'timestamp': DateTime.now().toIso8601String(),
          'geolocation': {
            'latitude': geolocation.latitude,
            'longitude': geolocation.longitude,
          },
          'status': 'completed',
        };

        await provider.submitInspection(
          inspectionData: inspectionData,
          photos: _photos,
          signaturePath: _signatureImagePath!,
        );

        // Show success and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inspection submitted successfully')),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
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
