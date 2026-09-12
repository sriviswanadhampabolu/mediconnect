import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/order_model.dart';
import '../providers/cart_provider.dart';
import '../core/services/api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final OrderResponse? initialOrder;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getOrderDetails(widget.orderId);
      setState(() {
        _orderDetails = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleManualPaymentConfirmation(CartProvider cart) async {
    final success = await cart.confirmPayment(widget.orderId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment authorized successfully! Delivery has been dispatched.'),
          backgroundColor: AppTheme.success,
        ),
      );
      _fetchOrder();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.orderError ?? 'Payment authorization failed'),
          backgroundColor: AppTheme.emergency,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final isConfirming = cart.isSubmitting;

    // Use details from API if loaded, otherwise fallback to initial order
    final status = _orderDetails?['status'] ?? widget.initialOrder?.status ?? 'CONFIRMED';
    final pharmacyName = _orderDetails?['pharmacy_name'] ?? widget.initialOrder?.pharmacyName ?? 'Neighborhood Chemist';
    final totalAmount = (_orderDetails?['total_amount'] ?? widget.initialOrder?.totalAmount ?? 0.0).toDouble();
    final genericSavings = (_orderDetails?['generic_savings'] ?? widget.initialOrder?.genericSavings ?? 0.0).toDouble();
    final subtotal = (_orderDetails?['subtotal'] ?? widget.initialOrder?.subtotal ?? 0.0).toDouble();
    final commission = (_orderDetails?['commission_applied'] ?? widget.initialOrder?.commissionAmount ?? 0.0).toDouble();
    final items = _orderDetails?['items'] as List<dynamic>? ?? [];

    final isHeldForPayment = status == 'PAYMENT_CONFIRMATION_REQUIRED';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Delivery Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Order #${widget.orderId}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: _isLoading ? null : _fetchOrder,
          ),
        ],
      ),
      body: _isLoading && _orderDetails == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.emergencyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.emergency, fontSize: 12)),
                  ),
                ],

                // Payment Limit Warning Banner (if held for confirmation)
                if (isHeldForPayment) ...[
                  _buildPaymentAuthorizationCard(totalAmount, isConfirming, () => _handleManualPaymentConfirmation(cart)),
                  const SizedBox(height: 16),
                ],

                // Delivery Status Progress Timeline
                _buildStatusTimeline(status),
                const SizedBox(height: 20),

                // Pharmacy & Runner Card
                _buildPharmacyAndRunnerCard(pharmacyName),
                const SizedBox(height: 20),

                // Ordered Items
                if (items.isNotEmpty) ...[
                  _buildItemsCard(items),
                  const SizedBox(height: 20),
                ],

                // Financial Breakdown & Capped Commission
                _buildFinancialBreakdown(subtotal, genericSavings, commission, totalAmount),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildPaymentAuthorizationCard(double total, bool isConfirming, VoidCallback onAuthorize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.warning, size: 22),
              SizedBox(width: 8),
              Text(
                'Payment Limit Authorization Required',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Order total (₹${total.toStringAsFixed(2)}) exceeds your server auto-pay limit (₹1,500.00). In accordance with MediConnect security rules, please authorize this transaction.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: isConfirming
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(isConfirming ? 'Authorizing Payment...' : 'Authorize Charge (₹${total.toStringAsFixed(2)})'),
              onPressed: isConfirming ? null : onAuthorize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    int currentStep = 1;
    if (status == 'PAYMENT_CONFIRMATION_REQUIRED') currentStep = 0;
    if (status == 'CONFIRMED' || status == 'PLACED') currentStep = 1;
    if (status == 'ACCEPTED') currentStep = 2;
    if (status == 'OUT_FOR_DELIVERY') currentStep = 3;
    if (status == 'DELIVERED') currentStep = 4;

    final steps = [
      {'title': 'Order Placed', 'desc': 'Received by system'},
      {'title': 'Chemist Accepted', 'desc': 'Packaging medicines'},
      {'title': 'Out for Delivery', 'desc': 'Hyperlocal runner dispatched'},
      {'title': 'Delivered', 'desc': 'Handed over at doorstep'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'DELIVERED'
                      ? AppTheme.successLight
                      : (status == 'PAYMENT_CONFIRMATION_REQUIRED' ? AppTheme.warningLight : AppTheme.primaryLight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: status == 'DELIVERED'
                        ? AppTheme.success
                        : (status == 'PAYMENT_CONFIRMATION_REQUIRED' ? AppTheme.warning : AppTheme.primaryDark),
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              const Text('ETA: 15–20 min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: i < currentStep
                            ? AppTheme.success
                            : (i == currentStep ? AppTheme.primary : AppTheme.border),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        i < currentStep ? Icons.check : (i == currentStep ? Icons.radio_button_checked : Icons.circle),
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 32,
                        color: i < currentStep ? AppTheme.success : AppTheme.border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i]['title']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: i <= currentStep ? FontWeight.bold : FontWeight.normal,
                          color: i <= currentStep ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        steps[i]['desc']!,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPharmacyAndRunnerCard(String pharmacyName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryLight,
                child: Icon(Icons.storefront, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pharmacyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Text('Local Neighborhood Chemist (0.4 km)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.secondaryLight,
                child: Icon(Icons.two_wheeler, color: AppTheme.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ramesh Kumar (Runner)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Hyperlocal 15-min delivery partner', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: AppTheme.primaryDark,
                ),
                icon: const Icon(Icons.phone, size: 18),
                tooltip: 'Call Delivery Runner',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling runner Ramesh Kumar (+91 98111 55667)...')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prescription & OTC Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (var item in items) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['medicine_name'] ?? 'Medicine', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        (item['is_generic'] == true ? 'Generic Affordable Formulation' : 'Branded Formulation'),
                        style: TextStyle(
                          fontSize: 11,
                          color: item['is_generic'] == true ? AppTheme.success : AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text('Qty: ${item['quantity'] ?? 1}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(width: 16),
                Text('₹${((item['unit_price'] ?? 0.0) * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const Divider(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialBreakdown(double subtotal, double genericSavings, double commission, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill & Commission Guardrails', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Medicine Subtotal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
            ],
          ),
          if (genericSavings > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.savings_outlined, color: AppTheme.success, size: 16),
                    SizedBox(width: 4),
                    Text('Generic Savings', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Text('- ₹${genericSavings.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('Community Chemist Fee', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  SizedBox(width: 4),
                  Text('(6.5% Capped)', style: TextStyle(color: AppTheme.primaryDark, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('₹${commission.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
              Text('₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryDark)),
            ],
          ),
        ],
      ),
    );
  }
}
