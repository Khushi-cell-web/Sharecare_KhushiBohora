import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../shared/providers/auth_provider.dart';
import '../core/services/sharecare_api_service.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/network_error_helper.dart';
import '../features/donations/widgets/donation_form_components.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  double? _pickupLat;
  double? _pickupLng;
  String _category = 'food';
  bool _loading = false;
  String? _error;
  final List<XFile> _pickedImages = [];
  final Map<int, Uint8List> _imageBytesCache = {};

  static const categories = [
    {'value': 'food', 'label': 'Food'},
    {'value': 'clothes', 'label': 'Clothes'},
    {'value': 'funds', 'label': 'Funds'},
    {'value': 'blood', 'label': 'Blood'},
    {'value': 'organ', 'label': 'Organ'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty && mounted) {
      final start = _pickedImages.length;
      setState(() => _pickedImages.addAll(picked));
      for (var i = 0; i < picked.length; i++) {
        picked[i].readAsBytes().then((bytes) {
          if (mounted) setState(() => _imageBytesCache[start + i] = bytes);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final api = ShareCareApiService();
    try {
      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final request = await api.createRequest(
        auth.authHeaders,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        quantityNeeded: quantity,
        location: _locationController.text.trim(),
        latitude: _pickupLat,
        longitude: _pickupLng,
      );
      final campaignId = request.id;
      for (var i = 0; i < _pickedImages.length; i++) {
        try {
          final bytes = await _pickedImages[i].readAsBytes();
          final name = _pickedImages[i].name;
          await api.uploadCampaignMedia(
            auth.authHeaders,
            campaignId: campaignId,
            imageBytes: bytes,
            fileName: name.isNotEmpty ? name : 'image_$i.jpg',
            isPrimary: i == 0,
          );
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request created')));
        Navigator.of(
          context,
        ).pushNamed(AppRoutes.requestDetail, arguments: request);
      }
    } on ShareCareApiException catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } catch (e) {
      if (mounted) setState(() => _error = NetworkErrorHelper.toUserMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.user?.role?.toLowerCase();
    final isNgo =
      role == 'ngo' || role == 'hospital' || role == 'admin';
    if (!isNgo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create donation request')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'Only verified NGO/Hospital accounts can create donation requests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Create donation request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['value'],
                        child: Text(c['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'food'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity needed',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null || int.parse(v) < 1) {
                    return 'Enter a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              PickupLocationField(
                controller: _locationController,
                hintText: 'Tap to pick on map or search address',
                initialLat: _pickupLat,
                initialLng: _pickupLng,
                onLocationPicked: (lat, lng, address) => setState(() {
                  _pickupLat = lat;
                  _pickupLng = lng;
                  _locationController.value = TextEditingValue(
                    text: address,
                    selection: TextSelection.collapsed(
                      offset: address.length,
                    ),
                  );
                }),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text(
                  _pickedImages.isEmpty
                      ? 'Add photos'
                      : '${_pickedImages.length} photo(s) added',
                ),
              ),
              if (_pickedImages.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _imageBytesCache.containsKey(i)
                            ? Image.memory(
                                _imageBytesCache[i]!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : SizedBox(
                                width: 80,
                                height: 80,
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
