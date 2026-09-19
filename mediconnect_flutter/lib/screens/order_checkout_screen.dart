import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import 'order_tracking_screen.dart';
import 'orders_list_screen.dart';

class OrderCheckoutScreen extends StatefulWidget {
  const OrderCheckoutScreen({super.key});

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  bool _bypassLimitConfirmation = false;

  void _handlePlaceOrder(CartProvider cart) async {
    if (cart.items.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userLimit = auth.safeAutoPayBalance;

    if (cart.checkExceedsLimit(userLimit) && !_bypassLimitConfirmation) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Text('🔒', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Expanded(child: Text('Safe Auto-Pay Limit Exceeded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(
            'The order total (₹${cart.finalTotal.toStringAsFixed(2)}) exceeds your configured Safe Auto-Pay Limit Guardrail (₹${userLimit.toStringAsFixed(2)}).\n\nUnder MediConnect safety rules, explicit manual authorization is required to approve this charge.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _bypassLimitConfirmation = true;
                });
                _executeOrder(cart, bypass: true);
              },
              child: const Text('Authorize Charge ➔'),
            ),
          ],
        ),
      );
      return;
    }

    _executeOrder(cart, bypass: _bypassLimitConfirmation);
  }

  void _executeOrder(CartProvider cart, {bool bypass = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'usr-sample-001';

    final response = await cart.submitOrder(bypassLimit: bypass, userId: userId);
    if (!mounted) return;

    if (response != null) {
      // Deduct order amount from Safe Auto-Pay Limit Guardrail
      auth.deductAutoPayAmount(response.totalAmount);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
          title: const Text('Order Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Order #${response.orderId} has been sent to ${response.pharmacyName}.'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text('Total Paid: ₹${response.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                    const SizedBox(height: 4),
                    Text('Auto-Pay Guardrail Remaining: ₹${(auth.currentUser?.paymentLimit ?? 1500).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                    if (response.genericSavings > 0) ...[
                      const SizedBox(height: 4),
                      Text('You saved ₹${response.genericSavings.toStringAsFixed(2)} by choosing generic!',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Neighborhood chemist has accepted the request. It now appears in your Orders section.'),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long, size: 16),
              label: const Text('View in Orders Section'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OrdersListScreen()),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.navigation, size: 16),
              label: const Text('Track Live Delivery'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(
                      orderId: response.orderId,
                      initialOrder: response,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Checkout'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => cart.clearCart(),
              child: const Text('Clear All', style: TextStyle(color: AppTheme.emergency)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Select medicines from nearby local pharmacies.', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Browse Nearby Shops'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Chemist Badge
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, color: AppTheme.primaryDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cart.selectedPharmacyName ?? 'Local Chemist',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark, fontSize: 14),
                            ),
                            const Text(
                              'Direct Order Fulfillment • 5–10% Capped Commission',
                              style: TextStyle(fontSize: 11, color: AppTheme.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cart Items List
                const Text('Medicines in Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                ...cart.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildCartItemCard(cart, index, item);
                }),
                const SizedBox(height: 16),

                // Financial Breakdown
                _buildFinancialSummary(cart),
                const SizedBox(height: 16),

                // Payment Safety Cap Banner
                if (cart.exceedsPaymentLimit) ...[
                  _buildPaymentLimitWarning(cart),
                  const SizedBox(height: 16),
                ],

                // Checkout Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primary,
                  ),
                  onPressed: cart.isSubmitting ? null : () => _handlePlaceOrder(cart),
                  child: cart.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ₹${cart.finalTotal.toStringAsFixed(2)} via UPI',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    '🔒 Encrypted & Verified under MediConnect Fair-Trade Guarantee',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(CartProvider cart, int index, item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.activeMedicineName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Unit: ₹${item.unitPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.textSecondary),
                    onPressed: () => cart.updateQuantity(index, item.quantity - 1),
                  ),
                  Text(
                    '${item.quantity}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primary),
                    onPressed: () => cart.updateQuantity(index, item.quantity + 1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Generic vs Brand Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, size: 16, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.useGeneric
                        ? 'Using Generic (Saved ₹${item.savings.toStringAsFixed(0)})'
                        : 'Using Brand (${item.brandedName})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.useGeneric ? AppTheme.success : AppTheme.textSecondary,
                    ),
                  ),
                ),
                Switch(
                  value: item.useGeneric,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => cart.toggleGeneric(index, val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(CartProvider cart) {
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
          const Text('Price Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Medicines Subtotal', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              Text('₹${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
          if (cart.totalSavings > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Generic Savings Discount', style: TextStyle(fontSize: 13, color: AppTheme.success, fontWeight: FontWeight.w600)),
                Text('- ₹${cart.totalSavings.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('Local Chemist Commission (6.5%)', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  SizedBox(width: 4),
                  Icon(Icons.verified, size: 14, color: AppTheme.primary),
                ],
              ),
              Text('₹${cart.commissionAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
          const Divider(height: 20, color: AppTheme.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text(
                '₹${cart.finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLimitWarning(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Server-Side Spending Guardrail',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'This order total (₹${cart.finalTotal.toStringAsFixed(2)}) exceeds the ₹1,500 safety threshold. Two-step confirmation is mandatory.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _bypassLimitConfirmation,
                activeColor: AppTheme.warning,
                onChanged: (val) {
                  setState(() {
                    _bypassLimitConfirmation = val ?? false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'I explicitly authorize charges above ₹1,500 for this order.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
