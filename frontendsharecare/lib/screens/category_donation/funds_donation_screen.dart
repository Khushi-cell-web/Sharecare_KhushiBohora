import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_routes.dart';
import '../../core/services/sharecare_api_service.dart';
import '../../core/utils/network_error_helper.dart';
import '../../core/utils/receipt_file_helper.dart';
import '../../shared/models/donation_request.dart';
import '../../shared/providers/auth_provider.dart';
import '../../features/donations/screens/donation_tracking_screen.dart';
import '../../widgets/esewa_webview_screen.dart';

/// Funds Donation: campaign selection, amount, purpose, eSewa/Stripe payment.
/// Success message and receipt only after backend confirmation.
enum _PaymentMethod { esewa, stripe }

bool get _isStripeKeyConfigured {
  final key = ApiConstants.stripePublishableKey;
  return key.isNotEmpty && !key.contains('placeholder');
}

class FundsDonationScreen extends StatefulWidget {
  const FundsDonationScreen({super.key, this.initialCampaign});

  final DonationRequest? initialCampaign;

  @override
  State<FundsDonationScreen> createState() => _FundsDonationScreenState();
}

class _FundsDonationScreenState extends State<FundsDonationScreen> {
  static const double _usdToNprRate = 133.0;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();

  List<DonationRequest> _campaigns = [];
  DonationRequest? _selectedCampaign;
  bool _loadingCampaigns = true;
  _PaymentMethod? _paymentMethod;

  bool _processing = false;
  bool _paymentSucceeded = false;
  int? _lastTransactionId;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isStripeKeyConfigured) {
      _paymentMethod = _PaymentMethod.stripe;
    }
    if (widget.initialCampaign != null) {
      _selectedCampaign = widget.initialCampaign;
      _loadingCampaigns = false;
    } else {
      _loadCampaigns();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      setState(() {
        _loadingCampaigns = false;
        _error = 'Please log in to donate.';
      });
      return;
    }
    setState(() {
      _loadingCampaigns = true;
      _error = null;
    });
    try {
      final list = await ShareCareApiService().getRequests(
        authHeaders: auth.authHeaders,
        status: 'open',
        category: 'funds',
      );
      if (mounted) {
        setState(() {
          _campaigns = list;
          _loadingCampaigns = false;
          _selectedCampaign = list.isNotEmpty ? list.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingCampaigns = false;
          _error = NetworkErrorHelper.toUserMessage(e);
        });
      }
    }
  }

  double get _amountValue {
    final v = double.tryParse(_amountController.text.trim());
    return v ?? 0;
  }

  double get _amountDollars {
    if (_paymentMethod == _PaymentMethod.esewa) {
      return (_amountValue / _usdToNprRate).clamp(0.5, 999999.99).toDouble();
    }
    return _amountValue.clamp(0.5, 999999.99).toDouble();
  }

  int get _amountNpr {
    if (_paymentMethod == _PaymentMethod.stripe) {
      return (_amountValue * _usdToNprRate).round().clamp(1, 999999).toInt();
    }
    return _amountValue.round().clamp(1, 999999).toInt();
  }

  double _convertAmount(
    double amount, {
    required _PaymentMethod from,
    required _PaymentMethod to,
  }) {
    if (amount <= 0 || from == to) return amount;
    if (from == _PaymentMethod.stripe && to == _PaymentMethod.esewa) {
      return amount * _usdToNprRate;
    }
    if (from == _PaymentMethod.esewa && to == _PaymentMethod.stripe) {
      return amount / _usdToNprRate;
    }
    return amount;
  }

  String _formatAmountForInput(double value, _PaymentMethod method) {
    if (method == _PaymentMethod.esewa) {
      return value.round().toString();
    }
    final fixed = value.toStringAsFixed(2);
    return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
  }

  void _onPaymentMethodSelected(_PaymentMethod method) {
    final current = _paymentMethod;
    if (current == method) return;
    final currentAmount = _amountValue;

    setState(() {
      if (current != null && currentAmount > 0) {
        final converted = _convertAmount(
          currentAmount,
          from: current,
          to: method,
        );
        _amountController.text = _formatAmountForInput(converted, method);
      }
      _paymentMethod = method;
    });
  }

  bool get _canProceed =>
      _selectedCampaign != null &&
      _amountValue > 0 &&
      _purposeController.text.trim().isNotEmpty &&
      _paymentMethod != null;

  String get _primaryPayLabel {
    if (_paymentMethod == null) return 'Select a payment method';
    if (_paymentMethod == _PaymentMethod.esewa) return 'Pay with eSewa';
    return 'Pay with card (Stripe)';
  }

  Future<void> _proceedToPay() async {
    if (!_formKey.currentState!.validate() || !_canProceed || _processing) {
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.accessToken == null) {
      setState(() => _error = 'Please log in to donate.');
      return;
    }

    final requestId = _selectedCampaign!.id;
    final headers = auth.authHeaders;
    final api = ShareCareApiService();

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      if (_paymentMethod == _PaymentMethod.esewa) {
        await _payWithEsewa(api, headers, requestId);
      } else {
        await _payWithStripe(api, headers, requestId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = NetworkErrorHelper.toUserMessage(e);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(NetworkErrorHelper.toUserMessage(e)),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _processing = false;
      _paymentSucceeded = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thank you! Your donation has been successfully processed.',
        ),
        backgroundColor: AppTheme.statusSuccess,
      ),
    );
  }

  Future<void> _payWithEsewa(
    ShareCareApiService api,
    Map<String, String> headers,
    int requestId,
  ) async {
    Map<String, dynamic> initData;
    try {
      initData = await api.esewaInit(
        headers,
        donationRequestId: requestId,
        amountNpr: _amountNpr.toDouble(),
      );
    } on ShareCareApiException catch (e) {
      if (e.statusCode == 503) {
        throw Exception('eSewa is not configured. Please use Stripe.');
      }
      rethrow;
    }

    debugPrint('eSewa init response: $initData');

    final formUrl = initData['form_url']?.toString();
    final formFieldsRaw = initData['form_data'];
    Map<String, dynamic>? formFields;
    if (formFieldsRaw is Map<String, dynamic>) {
      formFields = formFieldsRaw;
    } else if (formFieldsRaw is Map) {
      formFields = Map<String, dynamic>.from(formFieldsRaw);
    }
    if (formUrl == null || formUrl.trim().isEmpty) {
      throw Exception('Unable to load payment page');
    }
    if (formFields == null || formFields.isEmpty) {
      throw Exception('Unable to load payment page');
    }

    final transactionUuid = initData['transaction_uuid']?.toString();
    if (transactionUuid == null || transactionUuid.isEmpty) {
      throw Exception('Invalid response from server.');
    }
    final backendFormUrl =
        '${ApiConstants.baseUrl}${ApiConstants.paymentsPrefix}/esewa-form/?transaction_uuid=${Uri.encodeQueryComponent(transactionUuid)}';

    debugPrint('eSewa formUrl: $formUrl');
    debugPrint('eSewa backendFormUrl: $backendFormUrl');
    debugPrint('eSewa formFields: $formFields');

    final String selectedFormUrl = formUrl;
    final Map<String, dynamic> selectedFormFields = formFields;
    debugPrint('Using direct eSewa form data (validated).');

    if (!mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('eSewa Payment'),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.maybePop(ctx, false),
            ),
          ),
          body: EsewaWebViewScreen(
            backendFormUrl: null,
            formUrl: selectedFormUrl,
            formFields: selectedFormFields,
            onSuccess: () => Navigator.maybePop(ctx, true),
            onFailure: () => Navigator.maybePop(ctx, false),
          ),
        ),
      ),
    );
    if (result != true) {
      throw Exception('Payment was cancelled or failed.');
    }
  }

  Future<void> _payWithStripe(
    ShareCareApiService api,
    Map<String, String> headers,
    int requestId,
  ) async {
    final key = ApiConstants.stripePublishableKey;
    if (key.isEmpty || key.contains('placeholder')) {
      throw Exception(
        'Card payment is not configured. Add STRIPE_PUBLISHABLE_KEY to assets/.env',
      );
    }
    if (_amountDollars < 0.5) {
      throw Exception('Minimum amount is \$0.50 for card payments.');
    }

    Map<String, dynamic> intentData;
    try {
      intentData = await api.createPaymentIntent(
        headers,
        donationRequestId: requestId,
        amount: _amountDollars,
      );
    } on ShareCareApiException catch (e) {
      final lowerBody = e.body.toLowerCase();
      final looksStripeConfigIssue =
          lowerBody.contains('stripe is not configured') ||
          lowerBody.contains('set stripe_secret_key');
      if (e.statusCode == 503 || looksStripeConfigIssue) {
        throw Exception(
          'Stripe is not configured on server. Add STRIPE_SECRET_KEY to backend .env or use eSewa.',
        );
      }
      rethrow;
    }

    final clientSecret = intentData['client_secret'] as String?;
    final paymentIntentId = intentData['payment_intent_id'] as String?;
    if (clientSecret == null ||
        clientSecret.isEmpty ||
        paymentIntentId == null ||
        paymentIntentId.isEmpty) {
      throw Exception('Invalid response from server.');
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'ShareCare',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') ||
          msg.contains('cancelled') ||
          msg.contains('user cancelled')) {
        throw Exception('Payment was cancelled.');
      }
      if (msg.contains('paymentconfiguration') ||
          msg.contains('not initialized')) {
        throw Exception(
          'Card payment is not set up. Add STRIPE_PUBLISHABLE_KEY to assets/.env',
        );
      }
      rethrow;
    }

    final dt = await api.confirmPayment(
      headers,
      paymentIntentId: paymentIntentId,
      donationRequestId: requestId,
      amount: _amountDollars,
    );
    _lastTransactionId = dt.id;
  }

  Future<void> _downloadReceipt() async {
    if (!_paymentSucceeded || _selectedCampaign == null) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      final api = ShareCareApiService();
      List<int> bytes;
      if (_lastTransactionId != null) {
        bytes = await api.downloadReceiptForTransaction(
          auth.authHeaders,
          _lastTransactionId!,
        );
      } else {
        bytes = await api.downloadReceiptForRequest(
          auth.authHeaders,
          _selectedCampaign!.id,
        );
      }
      await saveAndOpenReceipt(
        bytes,
        'sharecare_receipt_${_selectedCampaign!.id}.pdf',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt opened'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkErrorHelper.toUserMessage(e)),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    }
  }

  Future<void> _openChatWithCampaignOwner() async {
    if (!_paymentSucceeded || _selectedCampaign == null) return;
    final ownerId = _selectedCampaign!.createdBy;
    if (ownerId == null) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      if (!mounted) return;
      final c = _selectedCampaign!;
      final ownerLabel =
          c.creatorFullName ??
          c.organization ??
          c.requestedByLabel ??
          c.createdByUsername ??
          'Campaign owner';
      await Navigator.of(context).pushNamed(
        AppRoutes.chatRoom,
        arguments: <String, dynamic>{
          'receiver_id': ownerId,
          'receiver_name': ownerLabel,
          'request_id': c.id,
          'context_subtitle': c.title,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(NetworkErrorHelper.toUserMessage(e)),
            backgroundColor: AppTheme.statusError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Funds Donation'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                icon: Icons.campaign_rounded,
                title: 'Select campaign',
              ),
              const SizedBox(height: AppTheme.spaceSm),
              if (_loadingCampaigns)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_campaigns.isEmpty && widget.initialCampaign == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'No fund campaigns available.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: _loadCampaigns,
                              child: const Text('Retry'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pushNamed(
                                AppRoutes.categoryRequests,
                                arguments: {
                                  'categoryKey': 'funds',
                                  'categoryLabel': 'Funds Donations',
                                  'subtitle': 'Financial support',
                                },
                              ),
                              child: const Text('Browse campaigns'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final list = widget.initialCampaign != null
                        ? [widget.initialCampaign!]
                        : _campaigns;
                    return DropdownButtonFormField<int>(
                      initialValue: _selectedCampaign?.id,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: list
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        DonationRequest? c;
                        for (final x in list) {
                          if (x.id == id) {
                            c = x;
                            break;
                          }
                        }
                        setState(() => _selectedCampaign = c);
                      },
                      validator: (v) => _selectedCampaign == null
                          ? 'Select a campaign'
                          : null,
                    );
                  },
                ),
              const SizedBox(height: AppTheme.spaceLg),
              _SectionHeader(
                icon: Icons.attach_money_rounded,
                title: 'Donation amount',
              ),
              const SizedBox(height: AppTheme.spaceSm),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: _paymentMethod == _PaymentMethod.esewa
                      ? 'Amount (NPR)'
                      : 'Amount (USD)',
                  prefixText: _paymentMethod == _PaymentMethod.esewa
                      ? 'NPR '
                      : '\$ ',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Enter valid amount';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              if (_paymentMethod != null && _amountValue > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _paymentMethod == _PaymentMethod.esewa
                        ? 'Approx. USD ${(_amountValue / _usdToNprRate).toStringAsFixed(2)} for card payment.'
                        : 'Approx. NPR ${(_amountValue * _usdToNprRate).round()} for eSewa payment.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              const SizedBox(height: AppTheme.spaceLg),
              _SectionHeader(
                icon: Icons.description_rounded,
                title: 'Purpose of fund usage',
              ),
              const SizedBox(height: AppTheme.spaceSm),
              TextFormField(
                controller: _purposeController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Food relief, medical aid, shelter',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter purpose';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              _SectionHeader(
                icon: Icons.payment_rounded,
                title: 'Payment gateway',
              ),
              const SizedBox(height: AppTheme.spaceSm),
              _PaymentMethodCard(
                icon: Icons.phone_android_rounded,
                title: 'eSewa',
                subtitle: 'Nepal mobile wallet',
                selected: _paymentMethod == _PaymentMethod.esewa,
                onTap: () => _onPaymentMethodSelected(_PaymentMethod.esewa),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              _PaymentMethodCard(
                icon: Icons.credit_card_rounded,
                title: 'Stripe',
                subtitle: 'Cards, Apple Pay & Google Pay (secure checkout)',
                selected: _paymentMethod == _PaymentMethod.stripe,
                onTap: () => _onPaymentMethodSelected(_PaymentMethod.stripe),
              ),
              if (_paymentMethod == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Select a payment method to continue',
                    style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: AppTheme.spaceMd),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.statusError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.statusError,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: AppTheme.statusError,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceXl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: (_canProceed && !_processing)
                      ? _proceedToPay
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: _processing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_primaryPayLabel),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXl),
              _SectionHeader(
                icon: Icons.receipt_long_rounded,
                title: 'Donation receipt',
              ),
              const SizedBox(height: AppTheme.spaceSm),
              OutlinedButton.icon(
                onPressed: _paymentSucceeded ? _downloadReceipt : null,
                icon: const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  _paymentSucceeded
                      ? 'Download receipt'
                      : 'Complete payment to download receipt',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
              if (_paymentSucceeded) ...[
                const SizedBox(height: AppTheme.spaceLg),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const DonationTrackingScreen(),
                    ),
                  ),
                  icon: Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  label: const Text('View donation tracking'),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                OutlinedButton.icon(
                  onPressed: _openChatWithCampaignOwner,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Chat with NGO/Hospital'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryTeal),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreenDark,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(
          color: selected ? AppTheme.primaryTeal : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppTheme.primaryTeal : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? AppTheme.primaryTeal : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal),
            ],
          ),
        ),
      ),
    );
  }
}
