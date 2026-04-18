import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../shared/providers/auth_provider.dart';
import 'p2p_donation_tracking_screen.dart';

class P2PDonationsListScreen extends StatefulWidget {
  const P2PDonationsListScreen({super.key});

  @override
  State<P2PDonationsListScreen> createState() => _P2PDonationsListScreenState();
}

class _P2PDonationsListScreenState extends State<P2PDonationsListScreen> {
  List<dynamic> _donations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDonations();
  }

  Future<void> _fetchDonations() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>().authHeaders;
      final data = await ShareCareApiService().getP2PDonations(auth);
      if (mounted) {
        setState(() {
          _donations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Donations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDonations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _donations.isEmpty
          ? const Center(child: Text('No P2P donations found.'))
          : ListView.builder(
              itemCount: _donations.length,
              itemBuilder: (context, index) {
                final item = _donations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      item['title'] ?? 'Unknown Item',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Status: ${item['status']}\nDonor: ${item['donor']?['username'] ?? 'Unknown'}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => P2PDonationTrackingScreen(
                              donationId: item['id'].toString(),
                            ),
                          ),
                        );
                      },
                      child: const Text('Track'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
