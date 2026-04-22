import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/sharecare_api_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/network_error_helper.dart';
import '../shared/providers/auth_provider.dart';

class CreateNgoRequestScreen extends StatefulWidget {
  const CreateNgoRequestScreen({super.key});

  @override
  State<CreateNgoRequestScreen> createState() => _CreateNgoRequestScreenState();
}

class _CreateNgoRequestScreenState extends State<CreateNgoRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  final _dietaryNeedsController = TextEditingController();
  final _clothingSizeController = TextEditingController();
  final _bloodUnitsController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _otherDetailsController = TextEditingController();

  String _category = 'food';
  String _urgency = 'Medium';
  String _foodType = 'Cooked meals';
  String _clothingType = 'Mixed';
  String _bloodGroup = 'O+';
  String _organType = 'Kidney';
  DateTime? _neededBefore;

  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();

    _dietaryNeedsController.dispose();
    _clothingSizeController.dispose();
    _bloodUnitsController.dispose();
    _hospitalController.dispose();
    _patientAgeController.dispose();
    _targetAmountController.dispose();
    _otherDetailsController.dispose();
    super.dispose();
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'food':
        return 'Food';
      case 'clothes':
        return 'Clothes';
      case 'blood':
        return 'Blood';
      case 'organ':
        return 'Organ';
      case 'funds':
        return 'Funds';
      default:
        return 'Other';
    }
  }

  String _failureMessage(ShareCareApiException e) {
    final body = e.body.toLowerCase();
    if (e.statusCode == 403 &&
        (body.contains('verified') || body.contains('verification'))) {
      return 'Your organization is not verified yet. Please complete verification first, then create the request again.';
    }
    return NetworkErrorHelper.toUserMessage(e);
  }

  Future<void> _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: success ? AppTheme.statusSuccess : AppTheme.statusError,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildExtraData() {
    final data = <String, dynamic>{};

    if (_contactNameController.text.trim().isNotEmpty) {
      data['contact_name'] = _contactNameController.text.trim();
    }
    if (_contactPhoneController.text.trim().isNotEmpty) {
      data['contact_phone'] = _contactPhoneController.text.trim();
    }
    if (_neededBefore != null) {
      data['needed_before'] = _neededBefore!.toIso8601String().split('T').first;
    }

    switch (_category) {
      case 'food':
        data['food_type'] = _foodType;
        if (_dietaryNeedsController.text.trim().isNotEmpty) {
          data['dietary_notes'] = _dietaryNeedsController.text.trim();
        }
        break;
      case 'clothes':
        data['clothing_type'] = _clothingType;
        if (_clothingSizeController.text.trim().isNotEmpty) {
          data['preferred_sizes'] = _clothingSizeController.text.trim();
        }
        break;
      case 'blood':
        data['blood_group'] = _bloodGroup;
        final units = int.tryParse(_bloodUnitsController.text.trim());
        if (units != null && units > 0) {
          data['units_required'] = units;
        }
        if (_hospitalController.text.trim().isNotEmpty) {
          data['hospital_name'] = _hospitalController.text.trim();
        }
        break;
      case 'organ':
        data['organ_type'] = _organType;
        final age = int.tryParse(_patientAgeController.text.trim());
        if (age != null && age > 0) {
          data['patient_age'] = age;
        }
        if (_hospitalController.text.trim().isNotEmpty) {
          data['hospital_name'] = _hospitalController.text.trim();
        }
        break;
      case 'funds':
        final amount = double.tryParse(_targetAmountController.text.trim());
        if (amount != null && amount > 0) {
          data['target_amount'] = amount;
        }
        break;
      case 'other':
        if (_otherDetailsController.text.trim().isNotEmpty) {
          data['details'] = _otherDetailsController.text.trim();
        }
        break;
    }

    return data;
  }

  Future<void> _pickNeededBefore() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _neededBefore ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _neededBefore = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      await _showResultDialog(
        success: false,
        title: 'Login Required',
        message: 'Please log in before creating a request.',
      );
      return;
    }

    int? quantityNeeded = int.tryParse(_quantityController.text.trim());
    if (_category == 'funds' &&
        (quantityNeeded == null || quantityNeeded < 1)) {
      final target = double.tryParse(_targetAmountController.text.trim());
      if (target != null && target > 0) {
        quantityNeeded = target.round();
      }
    }
    final safeQuantityNeeded = quantityNeeded ?? 1;

    setState(() => _loading = true);

    Future<void> createRequest() async {
      await ShareCareApiService().createRequest(
        auth.authHeaders,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        quantityNeeded: safeQuantityNeeded,
        location: _locationController.text.trim(),
        urgency: _urgency,
        extraData: _buildExtraData(),
      );
    }

    try {
      try {
        await createRequest();
      } on ShareCareApiException catch (e) {
        if (e.statusCode == 401) {
          final refreshed = await auth.tryRefreshToken();
          if (refreshed) {
            await createRequest();
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      setState(() => _loading = false);
      await _showResultDialog(
        success: true,
        title: 'Request Created',
        message:
            'Your ${_categoryLabel(_category)} request has been posted successfully. Donors can now respond to it.',
      );
      if (mounted) {
        Navigator.maybePop(context, true);
      }
    } on ShareCareApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await _showResultDialog(
        success: false,
        title: 'Request Not Created',
        message: _failureMessage(e),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await _showResultDialog(
        success: false,
        title: 'Request Not Created',
        message: NetworkErrorHelper.toUserMessage(e),
      );
    }
  }

  List<Widget> _categorySpecificFields() {
    switch (_category) {
      case 'food':
        return [
          DropdownButtonFormField<String>(
            initialValue: _foodType,
            decoration: const InputDecoration(labelText: 'Food Type'),
            items: const [
              DropdownMenuItem(
                value: 'Cooked meals',
                child: Text('Cooked meals'),
              ),
              DropdownMenuItem(value: 'Dry ration', child: Text('Dry ration')),
              DropdownMenuItem(value: 'Baby food', child: Text('Baby food')),
            ],
            onChanged: (val) =>
                setState(() => _foodType = val ?? 'Cooked meals'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dietaryNeedsController,
            decoration: const InputDecoration(
              labelText: 'Dietary Notes (optional)',
              hintText: 'e.g. Halal, low-salt, no peanuts',
            ),
          ),
        ];
      case 'clothes':
        return [
          DropdownButtonFormField<String>(
            initialValue: _clothingType,
            decoration: const InputDecoration(labelText: 'Clothing Type'),
            items: const [
              DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
              DropdownMenuItem(value: 'Men', child: Text('Men')),
              DropdownMenuItem(value: 'Women', child: Text('Women')),
              DropdownMenuItem(value: 'Children', child: Text('Children')),
            ],
            onChanged: (val) => setState(() => _clothingType = val ?? 'Mixed'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _clothingSizeController,
            decoration: const InputDecoration(
              labelText: 'Preferred Sizes (optional)',
              hintText: 'e.g. S, M, L and kids 8-12',
            ),
          ),
        ];
      case 'blood':
        return [
          DropdownButtonFormField<String>(
            initialValue: _bloodGroup,
            decoration: const InputDecoration(labelText: 'Blood Group'),
            items: const [
              DropdownMenuItem(value: 'A+', child: Text('A+')),
              DropdownMenuItem(value: 'A-', child: Text('A-')),
              DropdownMenuItem(value: 'B+', child: Text('B+')),
              DropdownMenuItem(value: 'B-', child: Text('B-')),
              DropdownMenuItem(value: 'O+', child: Text('O+')),
              DropdownMenuItem(value: 'O-', child: Text('O-')),
              DropdownMenuItem(value: 'AB+', child: Text('AB+')),
              DropdownMenuItem(value: 'AB-', child: Text('AB-')),
            ],
            onChanged: (val) => setState(() => _bloodGroup = val ?? 'O+'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bloodUnitsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Units Required (optional)',
              hintText: 'e.g. 2',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _hospitalController,
            decoration: const InputDecoration(
              labelText: 'Hospital Name (optional)',
            ),
          ),
        ];
      case 'organ':
        return [
          DropdownButtonFormField<String>(
            initialValue: _organType,
            decoration: const InputDecoration(labelText: 'Organ Needed'),
            items: const [
              DropdownMenuItem(value: 'Kidney', child: Text('Kidney')),
              DropdownMenuItem(value: 'Liver', child: Text('Liver')),
              DropdownMenuItem(value: 'Heart', child: Text('Heart')),
              DropdownMenuItem(value: 'Lung', child: Text('Lung')),
              DropdownMenuItem(value: 'Cornea', child: Text('Cornea')),
            ],
            onChanged: (val) => setState(() => _organType = val ?? 'Kidney'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _patientAgeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Patient Age (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _hospitalController,
            decoration: const InputDecoration(
              labelText: 'Hospital Name (optional)',
            ),
          ),
        ];
      case 'funds':
        return [
          TextFormField(
            controller: _targetAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Target Amount',
              hintText: 'e.g. 50000',
              prefixText: 'NPR ',
            ),
            validator: (v) {
              if (_category != 'funds') return null;
              final n = double.tryParse((v ?? '').trim());
              if (n == null || n <= 0) {
                return 'Enter a valid amount';
              }
              return null;
            },
          ),
        ];
      default:
        return [
          TextFormField(
            controller: _otherDetailsController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Additional Details',
              hintText: 'Describe what kind of support is needed',
            ),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantityLabel = _category == 'funds'
        ? 'Requested amount (fallback quantity)'
        : 'Quantity Needed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Request'),
        backgroundColor: AppTheme.primaryTeal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['food', 'clothes', 'blood', 'organ', 'funds', 'other']
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _category = val ?? 'food'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Request Title',
                  hintText: 'e.g. Emergency food support for 30 families',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter request title'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: quantityLabel),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final raw = (v ?? '').trim();
                  final n = int.tryParse(raw);
                  if (_category == 'funds' && raw.isEmpty) {
                    final target = double.tryParse(
                      _targetAmountController.text.trim(),
                    );
                    if (target != null && target > 0) {
                      return null;
                    }
                    return 'Enter quantity or target amount';
                  }
                  if (n == null || n < 1) return 'Enter valid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _urgency,
                decoration: const InputDecoration(labelText: 'Urgency'),
                items: ['Low', 'Medium', 'High']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (val) => setState(() => _urgency = val ?? 'Medium'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter description'
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                'Category Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ..._categorySpecificFields(),
              const SizedBox(height: 20),
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contactNameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone (optional)',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickNeededBefore,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(
                  _neededBefore == null
                      ? 'Set Needed Before Date (optional)'
                      : 'Needed before: ${_neededBefore!.day}/${_neededBefore!.month}/${_neededBefore!.year}',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
