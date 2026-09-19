import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/neu_background.dart';
import '../core/widgets/server_config_dialog.dart';
import '../core/services/api_service.dart';
import '../providers/auth_provider.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  // Inventory Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Active Chat Thread
  String? _selectedChatUserId;
  String? _selectedChatCustomerName;
  List<Map<String, dynamic>> _activeChatMessages = [];
  final TextEditingController _ownerReplyController = TextEditingController();
  bool _isLoadingChat = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _ownerReplyController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pharmacyId = auth.currentUser?.storeId ?? 'pharm-001';

    try {
      final data = await _apiService.getOwnerDashboard(pharmacyId);
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStock(String medicineId, int delta) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pharmacyId = auth.currentUser?.storeId ?? 'pharm-001';

    try {
      await _apiService.updateStock(
        pharmacyId: pharmacyId,
        medicineId: medicineId,
        delta: delta,
      );
      // Update local state smoothly
      if (_dashboardData != null && _dashboardData!['inventory'] != null) {
        final List<dynamic> inv = _dashboardData!['inventory'];
        for (var item in inv) {
          if (item['id'] == medicineId || item['generic_name'] == medicineId) {
            setState(() {
              item['stock'] = ((item['stock'] as num?)?.toInt() ?? 0) + delta;
              if (item['stock'] < 0) item['stock'] = 0;
            });
            break;
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock updated (${delta > 0 ? "+$delta" : delta})'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update stock: $e'), backgroundColor: AppTheme.emergency),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _apiService.updateOrderStatus(orderId: orderId, status: newStatus);
      _loadDashboard();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order #$orderId updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order status: $e'), backgroundColor: AppTheme.emergency),
        );
      }
    }
  }

  Future<void> _openChatWithCustomer(String userId, String customerName) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pharmacyId = auth.currentUser?.storeId ?? 'pharm-001';

    setState(() {
      _selectedChatUserId = userId;
      _selectedChatCustomerName = customerName;
      _isLoadingChat = true;
    });

    try {
      final msgs = await _apiService.getChatMessages(pharmacyId: pharmacyId, userId: userId);
      if (mounted) {
        setState(() {
          _activeChatMessages = msgs;
          _isLoadingChat = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingChat = false);
      }
    }
  }

  Future<void> _sendOwnerReply() async {
    final text = _ownerReplyController.text.trim();
    if (text.isEmpty || _selectedChatUserId == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pharmacyId = auth.currentUser?.storeId ?? 'pharm-001';
    final ownerName = auth.currentUser?.name ?? 'Store Owner';

    _ownerReplyController.clear();

    try {
      final sent = await _apiService.sendChatMessage(
        pharmacyId: pharmacyId,
        userId: _selectedChatUserId!,
        senderRole: 'owner',
        senderName: ownerName,
        message: text,
      );
      if (mounted) {
        setState(() {
          _activeChatMessages.add(sent);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reply: $e'), backgroundColor: AppTheme.emergency),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pharmacy = _dashboardData?['pharmacy'] ?? {};
    final salesSummary = _dashboardData?['sales_summary'] ?? {};
    final highestOrdered = (_dashboardData?['highest_ordered_medicines'] as List<dynamic>?) ?? [];
    final inventory = (_dashboardData?['inventory'] as List<dynamic>?) ?? [];
    final recentOrders = (_dashboardData?['recent_orders'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: AppTheme.secondary, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy['name'] ?? 'Chemist Store Portal',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Owner: ${auth.currentUser?.name ?? "Ramesh Gupta"}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Server Config Status Button
          InkWell(
            onTap: () => ServerConfigDialog.show(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: AppTheme.neuPill(
                active: ApiConstants.isSimulatorMode,
                activeColor: AppTheme.warning,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ApiConstants.isSimulatorMode ? Icons.bolt : Icons.wifi,
                    size: 13,
                    color: ApiConstants.isSimulatorMode ? AppTheme.warning : AppTheme.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ApiConstants.isSimulatorMode ? 'Sim' : 'Live',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: ApiConstants.isSimulatorMode ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.primary),
            tooltip: 'Switch to Patient View',
            onPressed: () {
              final cleanName = (auth.currentUser?.name ?? "Ramesh Gupta")
                  .replaceAll(RegExp(r'\((Store )?Owner\)', caseSensitive: false), '')
                  .replaceAll(RegExp(r'Sanjeevani Chemist', caseSensitive: false), 'Ramesh Gupta')
                  .trim();
              auth.switchRole('customer');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Switched to Patient view as $cleanName')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Dashboard',
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.emergency),
            tooltip: 'Logout',
            onPressed: () {
              auth.logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.secondary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.secondary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Daily Sales & Orders'),
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Stock & Catalog'),
            Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Customer Chats'),
          ],
        ),
      ),
      body: NeuBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $_errorMessage', style: const TextStyle(color: AppTheme.emergency)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadDashboard, child: const Text('Retry')),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: DAILY SALES & HIGHEST ORDERED MEDICINES
                      _buildSalesAndOrdersTab(salesSummary, highestOrdered, recentOrders),

                      // TAB 2: STOCK INVENTORY MANAGEMENT
                      _buildStockInventoryTab(inventory),

                      // TAB 3: CUSTOMER CHATS INBOX & DIRECT MESSAGING
                      _buildCustomerChatsTab(),
                    ],
                  ),
      ),
    );
  }

  // ==============================================================================
  // TAB 1: SALES, HIGHEST ORDERED MEDICINES & INCOMING ORDERS
  // ==============================================================================
  Widget _buildSalesAndOrdersTab(
    Map<String, dynamic> summary,
    List<dynamic> highestOrdered,
    List<dynamic> recentOrders,
  ) {
    final dailySales = (summary['daily_sales'] as num?)?.toDouble() ?? 0.0;
    final dailyOrders = (summary['daily_order_count'] as num?)?.toInt() ?? 0;
    final totalSales = (summary['total_sales_all_time'] as num?)?.toDouble() ?? 0.0;
    final lowStockCount = (summary['low_stock_items_count'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI Cards Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Today's Sales",
                value: '₹${dailySales.toStringAsFixed(2)}',
                subtitle: '$dailyOrders orders placed today',
                icon: Icons.currency_rupee_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Revenue',
                value: '₹${totalSales.toStringAsFixed(2)}',
                subtitle: 'All-time verified sales',
                icon: Icons.account_balance_wallet_outlined,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Commission Cap',
                value: '6.5% Max',
                subtitle: 'Transparent neighborhood fee',
                icon: Icons.verified_user_outlined,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Low Stock Alert',
                value: '$lowStockCount Items',
                subtitle: 'Reorder suggested soon',
                icon: Icons.warning_amber_rounded,
                color: lowStockCount > 0 ? AppTheme.emergency : AppTheme.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // HIGHEST ORDERED MEDICINE COUNTS SECTION
        Container(
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
                  const Icon(Icons.trending_up, color: AppTheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Highest Ordered Medicines (Demand Counts)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Top Moving', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (highestOrdered.isEmpty)
                const Text('No medicine order stats recorded yet.', style: TextStyle(color: AppTheme.textSecondary))
              else
                ...highestOrdered.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final medName = item['medicine_name'] ?? 'Medicine';
                  final count = item['order_count'] ?? 0;
                  final rev = (item['total_revenue'] as num?)?.toDouble() ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: index < 3 ? AppTheme.primaryLight : Colors.grey.shade200,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: index < 3 ? AppTheme.primaryDark : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(medName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('Total demand revenue: ₹${rev.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count ordered',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // RECENT INCOMING ORDERS SECTION
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Incoming Customer Orders',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recentOrders.isEmpty)
                const Text('No orders received yet.', style: TextStyle(color: AppTheme.textSecondary))
              else
                ...recentOrders.map((ord) {
                  final orderId = ord['order_id'] ?? '';
                  final customerName = ord['customer_name'] ?? 'Local Customer';
                  final total = (ord['total_amount'] as num?)?.toDouble() ?? 0.0;
                  final status = (ord['status'] ?? 'PLACED').toString();
                  final items = (ord['items'] as List<dynamic>?) ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#$orderId • $customerName',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: status == 'DELIVERED'
                                    ? AppTheme.successLight
                                    : status == 'CONFIRMED'
                                        ? AppTheme.primaryLight
                                        : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'DELIVERED'
                                      ? AppTheme.success
                                      : status == 'CONFIRMED'
                                          ? AppTheme.primary
                                          : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${items.length} items • Total: ₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (status != 'CONFIRMED' && status != 'DELIVERED')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  backgroundColor: AppTheme.primary,
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () => _updateOrderStatus(orderId, 'CONFIRMED'),
                                child: const Text('Accept & Prepare', style: TextStyle(fontSize: 11)),
                              ),
                            if (status == 'CONFIRMED')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  backgroundColor: Colors.deepPurple,
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () => _updateOrderStatus(orderId, 'OUT_FOR_DELIVERY'),
                                child: const Text('Dispatch Runner', style: TextStyle(fontSize: 11)),
                              ),
                            if (status == 'OUT_FOR_DELIVERY')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  backgroundColor: AppTheme.success,
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () => _updateOrderStatus(orderId, 'DELIVERED'),
                                child: const Text('Mark Delivered', style: TextStyle(fontSize: 11)),
                              ),
                            const Spacer(),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              icon: const Icon(Icons.chat_bubble_outline, size: 14),
                              label: const Text('Chat Customer', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                _tabController.animateTo(2);
                                _openChatWithCustomer(ord['customer_id'] ?? 'usr-sample-001', customerName);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ==============================================================================
  // TAB 2: STOCK INVENTORY MANAGEMENT
  // ==============================================================================
  Widget _buildStockInventoryTab(List<dynamic> inventory) {
    final filtered = inventory.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final gen = (item['generic_name'] ?? '').toString().toLowerCase();
      final brd = (item['branded_name'] ?? '').toString().toLowerCase();
      final cat = (item['category'] ?? '').toString().toLowerCase();
      return gen.contains(q) || brd.contains(q) || cat.contains(q);
    }).toList();

    return Column(
      children: [
        // Search & Filter Bar
        Container(
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search catalog by medicine, generic, or category...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Total Stock Counter Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Text(
                'Showing ${filtered.length} of ${inventory.length} medicines in store inventory',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),

        // Medicines Inventory List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              final id = item['id'] ?? '';
              final genName = item['generic_name'] ?? 'Generic';
              final brdName = item['branded_name'] ?? 'Brand';
              final category = item['category'] ?? 'General';
              final stock = (item['stock'] as num?)?.toInt() ?? 0;
              final genPrice = (item['generic_price'] as num?)?.toDouble() ?? 0.0;
              final brdPrice = (item['branded_price'] as num?)?.toDouble() ?? 0.0;
              final isLow = stock < 10;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isLow ? AppTheme.emergency.withOpacity(0.5) : AppTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(category, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                              ),
                              if (isLow) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emergencyLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('LOW STOCK', style: TextStyle(fontSize: 9, color: AppTheme.emergency, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(genName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Brand: $brdName', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Generic: ₹$genPrice | Brand: ₹$brdPrice', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                        ],
                      ),
                    ),

                    // Stock Counter with interactive +/- buttons
                    Column(
                      children: [
                        const Text('Available Stock', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.grey),
                              onPressed: stock > 0 ? () => _updateStock(id, -5) : null,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLow ? AppTheme.emergencyLight : AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$stock',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isLow ? AppTheme.emergency : AppTheme.primaryDark,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 22, color: AppTheme.primary),
                              onPressed: () => _updateStock(id, 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==============================================================================
  // TAB 3: CUSTOMER CHATS INBOX & DIRECT INTERACTION
  // ==============================================================================
  Widget _buildCustomerChatsTab() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pharmacyId = auth.currentUser?.storeId ?? 'pharm-001';

    return Row(
      children: [
        // Left Column: Customer Threads List
        Expanded(
          flex: 2,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _apiService.getChatThreads(pharmacyId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final threads = snapshot.data ?? [];
              if (threads.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('No Customer Conversations', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Customer inquiries from your neighborhood will appear here.',
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _openChatWithCustomer('usr-sample-001', 'Rahul Sharma'),
                          child: const Text('Test Chat with Rahul Sharma'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: threads.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = threads[index];
                  final uid = t['user_id'] ?? '';
                  final custName = t['customer_name'] ?? 'Customer';
                  final lastMsg = t['last_message'] ?? '';
                  final isSelected = _selectedChatUserId == uid;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppTheme.secondary.withOpacity(0.08),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(custName.isNotEmpty ? custName[0] : 'C', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                    ),
                    title: Text(custName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    onTap: () => _openChatWithCustomer(uid, custName),
                  );
                },
              );
            },
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Column: Active Conversation Panel
        Expanded(
          flex: 3,
          child: _selectedChatUserId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.question_answer_outlined, size: 50, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Select a customer inquiry to reply', style: TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _openChatWithCustomer('usr-sample-001', 'Rahul Sharma'),
                        child: const Text('Open Conversation with Rahul Sharma'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Chat Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryLight,
                            child: Text(
                              _selectedChatCustomerName != null && _selectedChatCustomerName!.isNotEmpty
                                  ? _selectedChatCustomerName![0]
                                  : 'C',
                              style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedChatCustomerName ?? 'Customer',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text('Customer Inquiring about Medicines', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Messages List
                    Expanded(
                      child: _isLoadingChat
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _activeChatMessages.length,
                              itemBuilder: (context, index) {
                                final m = _activeChatMessages[index];
                                final isOwner = m['sender_role'] == 'owner';
                                final text = m['message'] ?? '';

                                return Align(
                                  alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    constraints: const BoxConstraints(maxWidth: 320),
                                    decoration: BoxDecoration(
                                      color: isOwner ? AppTheme.secondary : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: isOwner ? null : Border.all(color: AppTheme.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isOwner ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          text,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isOwner ? Colors.white : AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isOwner ? 'Store Owner' : (_selectedChatCustomerName ?? 'Customer'),
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isOwner ? Colors.white70 : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Reply Input Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ownerReplyController,
                              decoration: const InputDecoration(
                                hintText: 'Type your reply to customer...',
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onSubmitted: (_) => _sendOwnerReply(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            onPressed: _sendOwnerReply,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
