import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/sharecare_api_service.dart';
import '../core/theme/app_theme.dart';
import '../shared/providers/auth_provider.dart';
import '../core/utils/network_error_helper.dart';

class CreateNgoRequestScreen extends StatefulWidget {
  const CreateNgoRequestScreen({super.key});

  @override
  State<CreateNgoRequestScreen> createState() => _CreateNgoRequestScreenState();
}

class _CreateNgoRequestScreenState extends State<CreateNgoRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'food';
  String _urgency = 'Medium';
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);

    try {
      await ShareCareApiService().createRequest(
        auth.authHeaders,
        title: 'Need $_category',
        description: _descriptionController.text.trim(),
        category: _category,
        quantityNeeded: int.tryParse(_quantityController.text) ?? 1,
        location: _locationController.text.trim(),
        urgency: _urgency,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request created successfully!'),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
        Navigator.maybePop(context, true);
      }
    } on ShareCareApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkErrorHelper.toUserMessage(e)),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity Needed'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => v!.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _urgency,
                decoration: const InputDecoration(labelText: 'Urgency'),
                items: ['Low', 'Medium', 'High']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (val) => setState(() => _urgency = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Enter description' : null,
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
