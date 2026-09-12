import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/pharmacy_provider.dart';
import '../providers/cart_provider.dart';
import '../models/pharmacy_model.dart';
import 'chemist_chat_screen.dart';
import 'order_checkout_screen.dart';

class PharmacyListScreen extends StatefulWidget {
  const PharmacyListScreen({super.key});

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PharmacyProvider>(context, listen: false).fetchNearbyPharmacies();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyProv = Provider.of<PharmacyProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyperlocal Pharmacies'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => pharmacyProv.fetchNearbyPharmacies(query: _searchController.text),
          ),
        ],
      ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.items.length} items from ${cart.selectedPharmacyName ?? "Local Chemist"}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Text(
                          '₹${cart.finalTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                      label: const Text('Checkout (6.5% Cap)'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OrderCheckoutScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
      body: Column(
        children: [
          // Search & Generic Savings Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search medicine (e.g. Paracetamol, Cetirizine)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              pharmacyProv.fetchNearbyPharmacies();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (val) {
                    pharmacyProv.fetchNearbyPharmacies(query: val.trim());
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showLocationSelector(context, pharmacyProv),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              pharmacyProv.currentLocation.name,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Capped 6.5% max commission',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pharmacy List
          Expanded(
            child: pharmacyProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : pharmacyProv.pharmacies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.storefront, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text('No verified local pharmacies found.', style: TextStyle(color: AppTheme.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => pharmacyProv.fetchNearbyPharmacies(),
                              child: const Text('Reload Nearby Shops'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pharmacyProv.pharmacies.length,
                        itemBuilder: (context, index) {
                          final pharmacy = pharmacyProv.pharmacies[index];
                          return _buildPharmacyCard(pharmacy, cart);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(Pharmacy pharmacy, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chemist Header Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_pharmacy, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              pharmacy.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Verified Local',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pharmacy.address,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.directions_walk, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${pharmacy.distanceKm.toStringAsFixed(2)} km (~${(pharmacy.distanceKm * 12).ceil()} mins)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 14, color: AppTheme.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${pharmacy.rating}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Direct Chemist Chat Button
                IconButton(
                  tooltip: 'Chat with Chemist',
                  icon: const Icon(Icons.chat_outlined, color: AppTheme.secondary),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChemistChatScreen(pharmacy: pharmacy),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.border),

          // Inventory & Add to Cart
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Stock & Generic Pricing',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 10),
                ...pharmacy.inventory.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.genericName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              Text(
                                'Brand: ${item.brandedName}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Generic: ₹${item.genericPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Brand: ₹${item.brandedPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Save ₹${item.potentialSavings.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                '+ Add (₹${item.genericPrice.toStringAsFixed(0)})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                cart.addItemFromInventory(item, pharmacy, useGeneric: true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added ${item.genericName} to cart!'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
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
      ),
    );
  }

  void _showLocationSelector(BuildContext context, PharmacyProvider pharmacyProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 8),
                    const Text('Choose Your Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...PharmacyProvider.locationPresets.map((loc) {
                  final isSelected = pharmacyProv.currentLocation.id == loc.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.location_on_outlined,
                        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                      title: Text(
                        loc.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Featured Chemist: ${loc.expectedPrimaryShop} (${loc.area})',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppTheme.primary, size: 20)
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        pharmacyProv.changeLocation(loc);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

