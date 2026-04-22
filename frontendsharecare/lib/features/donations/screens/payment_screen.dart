import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/sharecare_api_service.dart';
import '../../../core/utils/network_error_helper.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/donation_request.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';

bool get _isStripeConfigured {
  final key = ApiConstants.stripePublishableKey;
  return key.isNotEmpty && !key.contains('placeholder');
}

/// Money checkout and goods offer flow.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.request,
    required this.amount,
    required this.donationType,
    this.fulfillmentType,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.offerMessage,
  });

  final DonationRequestModel request;
  final int amount;
  final String donationType;

  /// Material modes: self_dropoff or volunteer_pickup.
  final String? fulfillmentType;
  final String? pickupLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? offerMessage;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _PaymentMethod { card, esewa }

class _PaymentScreenState extends State<PaymentScreen> {
  static const double _usdToNprRate = 133.0;

  bool _paying = false;
  String? _error;
  _PaymentMethod _method = _PaymentMethod.card;

  bool get _isMoney => widget.donationType == 'money';

  /// Money uses these values; goods skip payment gateways.
  double get _amountDollars {
    if (!_isMoney) return 0;
    if (_method == _PaymentMethod.esewa) {
      return (widget.amount / _usdToNprRate).clamp(0.5, 999999.99).toDouble();
    }
    return widget.amount.toDouble();
  }

  int get _amountNpr {
    if (!_isMoney) return 0;
    if (_method == _PaymentMethod.card) {
      return (widget.amount * _usdToNprRate).round().clamp(1, 999999).toInt();
    }
    return widget.amount.clamp(1, 999999).toInt();
  }

  Future<void> _pay() async {
    if (_paying) return;
    setState(() {
      _paying = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.accessToken == null) {
      setState(() {
        _paying = false;
        _error = 'Please log in to donate.';
      });
      return;
    }

    final headers = auth.authHeaders;
    final api = ShareCareApiService();
    final requestId = int.tryParse(widget.request.id);

    try {
      if (widget.request.isBloodRequest) {
        final el = await api.getBloodDonationEligibility(headers);
        if (el['eligible'] != true) {
          if (mounted) {
            setState(() {
              _paying = false;
              _error =
                  el['message'] as String? ??
                  'You can donate blood only after 3 months from your last donation';
            });
          }
          return;
        }
      }

      if (!_isMoney && requestId != null) {
        await _submitGoodsOffer(api, headers, requestId);
      } else if (_isMoney && requestId != null) {
        if (_method == _PaymentMethod.esewa) {
          await _payWithEsewa(api, headers, requestId);
          return;
        }
        if (_method == _PaymentMethod.card) {
          if (!_isStripeConfigured) {
            setState(() {
              _paying = false;
              _error =
                  'Card payment is not configured. Add STRIPE_PUBLISHABLE_KEY to assets/.env (pk_test_...).';
            });
            return;
          }
          if (_amountDollars < 0.5) {
            throw Exception('Minimum amount for card payment is \$0.50');
          }
          final paid = await _payWithStripe(api, headers, requestId);
          if (!paid) {
            if (mounted) setState(() => _paying = false);
            return;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = NetworkErrorHelper.toUserMessage(e);
      });
      return;
    }

    if (!mounted) return;
    setState(() => _paying = false);
    _showSuccessAndNavigate();
  }

  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isMoney ? 'Payment successful!' : 'Offer submitted successfully!',
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
    // Avoid popping when this screen is already the root route.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  Future<void> _payWithEsewa(
    ShareCareApiService api,
    Map<String, String> headers,
    int requestId,
  ) async {
    Map<String, dynamic> initData;
    try {
      initData = await api.esewaMobileInit(
        headers,
        donationRequestId: requestId,
        amountNpr: _amountNpr.toDouble(),
      );
    } on ShareCareApiException catch (e) {
      if (e.statusCode == 503) {
        setState(() {
          _paying = false;
          _error = 'eSewa is not configured. Use Card or Other.';
        });
        return;
      }
      rethrow;
    }

    final productId =
        initData['product_id']?.toString() ??
        initData['productId']?.toString() ??
        initData['transaction_uuid']?.toString() ??
        '';
    final productName = initData['product_name']?.toString() ?? 'Donation';
    final productPrice = initData['amount']?.toString() ?? '1';

    if (productId.isEmpty) {
      final detail =
          initData['detail']?.toString() ??
          initData['message']?.toString() ??
          '';
      setState(() {
        _paying = false;
        _error = detail.isNotEmpty
            ? 'eSewa init failed: $detail'
            : 'Invalid response from server. Please check backend payment setup.';
      });
      return;
    }

    setState(() => _paying = false); // Let SDK take over UI

    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test,
          clientId: 'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R',
          secretId: 'BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==',
        ),
        esewaPayment: EsewaPayment(
          productId: productId,
          productName: productName,
          productPrice: productPrice,
          callbackUrl: '${ApiConstants.baseUrl}/api/payments/esewa-callback/',
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult data) async {
          debugPrint('eSewa SUCCESS: ${data.productId}');
          setState(() {
            _paying = true;
            _error = null;
          });
          try {
            await api.esewaMobileConfirm(
              headers,
              productId: data.productId,
              refId: data.refId,
              totalAmount: double.parse(data.totalAmount),
            );
            if (!mounted) return;
            setState(() => _paying = false);
            _showSuccessAndNavigate();
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _paying = false;
              _error = 'Verification failed: $e';
            });
          }
        },
        onPaymentFailure: (data) {
          debugPrint('eSewa FAILURE: $data');
          if (mounted) {
            setState(() {
              _error = 'Payment failed: $data';
            });
          }
        },
        onPaymentCancellation: (data) {
          debugPrint('eSewa CANCELED: $data');
          if (mounted) {
            setState(() {
              _error = 'Payment was cancelled.';
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _paying = false;
        _error = 'Error starting eSewa: ${e.toString()}';
      });
    }
  }

  Future<bool> _payWithStripe(
    ShareCareApiService api,
    Map<String, String> headers,
    int requestId,
  ) async {
    final amount = _amountDollars;
    Map<String, dynamic> intentData;
    intentData = await api.createPaymentIntent(
      headers,
      donationRequestId: requestId,
      amount: amount,
    );

    final clientSecret = intentData['client_secret'] as String?;
    final paymentIntentId = intentData['payment_intent_id'] as String?;
    if (clientSecret == null ||
        clientSecret.isEmpty ||
        paymentIntentId == null ||
        paymentIntentId.isEmpty) {
      throw Exception('Invalid payment response from server');
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
        return false;
      }
      if (msg.contains('paymentconfiguration') ||
          msg.contains('not initialized')) {
        throw Exception(
          'Card payment is not set up. Add STRIPE_PUBLISHABLE_KEY to assets/.env',
        );
      }
      rethrow;
    }

    await api.confirmPayment(
      headers,
      paymentIntentId: paymentIntentId,
      donationRequestId: requestId,
      amount: amount,
    );

    return true;
  }

  Future<void> _submitGoodsOffer(
    ShareCareApiService api,
    Map<String, String> headers,
    int? requestId,
  ) async {
    if (requestId == null) throw Exception('Invalid campaign');
    await api.createOffer(
      headers,
      donationRequestId: requestId,
      type: 'material',
      quantity: widget.amount,
      message: widget.offerMessage,
      fulfillmentType: widget.fulfillmentType ?? 'volunteer_pickup',
      pickupLocation: widget.pickupLocation,
      pickupLatitude: widget.pickupLatitude,
      pickupLongitude: widget.pickupLongitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMoney = _isMoney;
    final displayAmount = isMoney
        ? (_method == _PaymentMethod.esewa
              ? 'NPR $_amountNpr'
              : '\$${_amountDollars.toStringAsFixed(2)}')
        : 'In-kind';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryGreenDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Donation for'),
                        Expanded(
                          child: Text(
                            widget.request.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMoney ? 'Amount' : 'Type',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          isMoney
                              ? displayAmount
                              : 'Goods (qty: ${widget.amount})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isMoney) ...[
              const SizedBox(height: 24),
              Text(
                'Payment gateway',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryGreenDark,
                ),
              ),
              const SizedBox(height: 12),
              _PaymentOption(
                icon: Icons.credit_card_rounded,
                title: 'Stripe',
                subtitle: 'Cards, Apple Pay & Google Pay',
                selected: _method == _PaymentMethod.card,
                onTap: () => setState(() => _method = _PaymentMethod.card),
              ),
              const SizedBox(height: 8),
              _PaymentOption(
                icon: Icons.phone_android_rounded,
                title: 'eSewa',
                subtitle: 'Nepal mobile wallet',
                selected: _method == _PaymentMethod.esewa,
                onTap: () => setState(() => _method = _PaymentMethod.esewa),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _paying ? null : _pay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _paying
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isMoney
                            ? (_method == _PaymentMethod.esewa
                                  ? 'Pay with eSewa'
                                  : 'Pay with card (Stripe)')
                            : 'Submit Offer',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppTheme.primaryGreen : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen),
            ],
          ),
        ),
      ),
    );
  }
}
