import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/models/donation_request.dart';
import '../shared/providers/auth_provider.dart';
import '../core/services/sharecare_api_service.dart';
import '../core/utils/network_error_helper.dart';
import '../core/theme/app_theme.dart';

class VolunteerAcceptTaskScreen extends StatefulWidget {
  const VolunteerAcceptTaskScreen({super.key});

  @override
  State<VolunteerAcceptTaskScreen> createState() =>
      _VolunteerAcceptTaskScreenState();
}

class _VolunteerAcceptTaskScreenState extends State<VolunteerAcceptTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final request =
        ModalRoute.of(context)!.settings.arguments as DonationRequest?;
    if (request != null) {
      _pickupController.text = request.location;
      _deliveryController.text = request.location;
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  Future<void> _submit(DonationRequest request) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final api = ShareCareApiService();
    try {
      await api.createTask(
        auth.authHeaders,
        donationRequestId: request.id,
        pickupLocation: _pickupController.text.trim(),
        deliveryLocation: _deliveryController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task accepted'),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
        Navigator.maybePop(context, true);
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
    final request =
        ModalRoute.of(context)!.settings.arguments! as DonationRequest;

    return Scaffold(
      appBar: AppBar(title: const Text('Accept volunteer task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  title: Text(request.title),
                  subtitle: Text(
                    '${request.categoryDisplay ?? request.category} • ${request.location}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                controller: _pickupController,
                decoration: const InputDecoration(
                  labelText: 'Pickup location',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deliveryController,
                decoration: const InputDecoration(
                  labelText: 'Delivery location',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : () => _submit(request),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Accept task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
