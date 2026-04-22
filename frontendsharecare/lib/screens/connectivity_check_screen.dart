import 'package:flutter/material.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/health_check_service.dart';

/// Shows backend connectivity status on app startup.
class ConnectivityCheckScreen extends StatefulWidget {
  final VoidCallback onConnected;

  const ConnectivityCheckScreen({required this.onConnected, super.key});

  @override
  State<ConnectivityCheckScreen> createState() =>
      _ConnectivityCheckScreenState();
}

class _ConnectivityCheckScreenState extends State<ConnectivityCheckScreen> {
  late Future<(bool, String?)> _healthCheckFuture;

  @override
  void initState() {
    super.initState();
    _healthCheckFuture = HealthCheckService().check();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<(bool, String?)>(
        future: _healthCheckFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting to ShareCare...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Backend URL: ${ApiConstants.resolvedBaseUrl}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            final (success, error) = snapshot.data!;

            if (success) {
              // Delay slightly to let the user see the success state
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  widget.onConnected();
                }
              });

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Backend Connected',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.green),
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Backend Not Connected',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Error: ${error ?? "Unknown error"}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.red.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Trying URL: ${ApiConstants.resolvedBaseUrl}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.red.shade700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fix Checklist:',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildCheckItem(
                                '1. Django running: python manage.py runserver 0.0.0.0:8000',
                              ),
                              _buildCheckItem(
                                '2. Device on same Wi-Fi network as PC',
                              ),
                              _buildCheckItem(
                                '3. PC firewall allows port 8000',
                              ),
                              _buildCheckItem(
                                '4. PC IPv4 address correct in .env or dart-define',
                              ),
                              _buildCheckItem(
                                '5. No VPN or proxy blocking connection',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _healthCheckFuture = HealthCheckService().check();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }

          // Error state
          return Center(child: Text('Unexpected error: ${snapshot.error}'));
        },
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
