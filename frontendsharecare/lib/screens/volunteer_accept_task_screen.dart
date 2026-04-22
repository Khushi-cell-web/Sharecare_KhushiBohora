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
  DonationRequest? _request;
  bool _initializedFromArgs = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromArgs) return;
    _initializedFromArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DonationRequest) {
      _request = args;
      _pickupController.text = args.location;
      _deliveryController.text = args.location;
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final request = _request;
    if (request == null) {
      setState(() => _error = 'Unable to open this request. Please go back.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final api = ShareCareApiService();
    try {
      Future<void> createTask() async {
        await api.createTask(
          auth.authHeaders,
          donationRequestId: request.id,
          pickupLocation: _pickupController.text.trim(),
          deliveryLocation: _deliveryController.text.trim(),
        );
      }

      try {
        await createTask();
      } on ShareCareApiException catch (e) {
        if (e.statusCode == 401) {
          final refreshed = await auth.tryRefreshToken();
          if (refreshed) {
            await createTask();
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

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
    final request = _request;

    if (request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accept volunteer task')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Could not load this request. Please go back and try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

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
                onPressed: _loading ? null : _submit,
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
