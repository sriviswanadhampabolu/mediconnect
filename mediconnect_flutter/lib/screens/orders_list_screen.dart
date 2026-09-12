import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/pharmacy_provider.dart';
import '../models/order_model.dart';
import 'order_tracking_screen.dart';
import 'chemist_chat_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.currentUser?.id ?? 'usr-sample-001';
    Provider.of<CartProvider>(context, listen: false).fetchUserOrders(userId);
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return AppTheme.success;
      case 'OUT_FOR_DELIVERY':
        return Colors.deepPurple;
      case 'PREPARING':
      case 'CONFIRMED':
        return AppTheme.primary;
      case 'PLACED':
        return Colors.orange;
      case 'CANCELLED':
        return AppTheme.emergency;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orders = cart.userOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Medicine Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadOrders(),
        child: cart.isLoadingOrders && orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : orders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 56, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Orders Placed Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search for medicines or describe your symptoms to find verified generic alternatives and order from your local chemist.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Explore Medicines & Stores'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? 'PLACED').toString();
    final statusColor = _getStatusColor(status);
    final pharmacyName = order['pharmacy_name'] ?? 'Local Chemist';
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final genericSavings = (order['generic_savings'] as num?)?.toDouble() ?? 0.0;
    final orderId = order['order_id'] ?? '';
    final createdAtStr = order['created_at'] ?? '';
    
    DateTime? dt;
    try {
      dt = DateTime.parse(createdAtStr);
    } catch (_) {}
    final formattedDate = dt != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(dt) : 'Recent';

    final items = (order['items'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Store Name & Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacyName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '#$orderId • $formattedDate',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Order Items List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((it) {
                  final name = it['medicine_name'] ?? 'Medicine';
                  final qty = it['quantity'] ?? 1;
                  final price = (it['unit_price'] as num?)?.toDouble() ?? 0.0;
                  final isGeneric = it['is_generic'] == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          '${qty}x',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isGeneric) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('GENERIC', style: TextStyle(color: AppTheme.success, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '₹${(price * qty).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(height: 20),

                // Savings & Total Paid
                Row(
                  children: [
                    if (genericSavings > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.savings_outlined, size: 14, color: AppTheme.success),
                            const SizedBox(width: 4),
                            Text(
                              'Saved ₹${genericSavings.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    const Text('Total: ', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Chat Chemist', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          final pharmProv = Provider.of<PharmacyProvider>(context, listen: false);
                          final matchedPharm = pharmProv.pharmacies.firstWhere(
                            (p) => p.id == order['pharmacy_id'],
                            orElse: () => pharmProv.selectedPharmacy ?? pharmProv.pharmacies.first,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ChemistChatScreen(pharmacy: matchedPharm)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.navigation_outlined, size: 16),
                        label: const Text('Track Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final mockOrderResp = OrderResponse(
                            orderId: orderId,
                            pharmacyId: order['pharmacy_id'] ?? 'pharm-001',
                            pharmacyName: pharmacyName,
                            status: status,
                            subtotal: (order['subtotal'] as num?)?.toDouble() ?? totalAmount,
                            genericSavings: genericSavings,
                            totalAmount: totalAmount,
                            commissionRatePercent: 6.5,
                            commissionAmount: totalAmount * 0.065,
                            autoPayApproved: true,
                            requiresManualConfirmation: false,
                            message: 'Order active and verified by local chemist.',
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => OrderTrackingScreen(
                                orderId: orderId,
                                initialOrder: mockOrderResp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
