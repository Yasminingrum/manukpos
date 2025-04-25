// widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/user.dart';
import '../models/branch.dart';

class CustomDrawer extends StatefulWidget {
  final User? user;
  final Branch? branch;
  final VoidCallback? onLogout;

  const CustomDrawer({
    super.key,
    this.user,
    this.branch,
    this.onLogout,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  
  // Define menu sections
  final Map<String, List<DrawerMenuItem>> _menuSections = {};
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    // Initialize menu sections
    _menuSections['main'] = [
      DrawerMenuItem(
        icon: Icons.dashboard,
        title: 'Dashboard',
        route: AppRouter.dashboard,
      ),
    ];
    
    _menuSections['transactions'] = [
      DrawerMenuItem(
        icon: Icons.point_of_sale,
        title: 'Kasir (POS)',
        route: AppRouter.pos,
      ),
      DrawerMenuItem(
        icon: Icons.shopping_cart,
        title: 'Pembelian',
        route: AppRouter.purchasing,
      ),
      DrawerMenuItem(
        icon: Icons.receipt_long,
        title: 'Riwayat Transaksi',
        route: AppRouter.transactionHistory,
      ),
    ];
    
    _menuSections['inventory'] = [
      DrawerMenuItem(
        icon: Icons.inventory_2,
        title: 'Produk',
        route: AppRouter.products,
      ),
      DrawerMenuItem(
        icon: Icons.category,
        title: 'Kategori',
        route: AppRouter.categories,
      ),
      DrawerMenuItem(
        icon: Icons.assessment,
        title: 'Stock Opname',
        route: AppRouter.stockOpname,
      ),
    ];
    
    _menuSections['contacts'] = [
      DrawerMenuItem(
        icon: Icons.people,
        title: 'Pelanggan',
        route: AppRouter.customers,
      ),
      DrawerMenuItem(
        icon: Icons.local_shipping,
        title: 'Supplier',
        route: AppRouter.suppliers,
      ),
    ];
    
    _menuSections['reports'] = [
      DrawerMenuItem(
        icon: Icons.bar_chart,
        title: 'Laporan Penjualan',
        route: AppRouter.salesReport,
      ),
      DrawerMenuItem(
        icon: Icons.inventory,
        title: 'Laporan Inventori',
        route: AppRouter.inventoryReport,
      ),
      DrawerMenuItem(
        icon: Icons.account_balance_wallet,
        title: 'Laporan Keuangan',
        route: AppRouter.financialReport,
      ),
    ];
    
    _menuSections['settings'] = [
      DrawerMenuItem(
        icon: Icons.business,
        title: 'Profil Bisnis',
        route: AppRouter.businessProfile,
      ),
      DrawerMenuItem(
        icon: Icons.people_alt,
        title: 'Pengguna',
        route: AppRouter.userManagement,
      ),
      DrawerMenuItem(
        icon: Icons.settings,
        title: 'Pengaturan Aplikasi',
        route: AppRouter.appSettings,
      ),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Main menu
                    ..._buildMenuItems(_menuSections['main']!, 'main'),
                    
                    // Transactions section
                    _buildSectionHeader(context, 'Transaksi'),
                    ..._buildMenuItems(_menuSections['transactions']!, 'Transaksi'),
                    
                    // Inventory section
                    _buildSectionHeader(context, 'Inventori'),
                    ..._buildMenuItems(_menuSections['inventory']!, 'Inventori'),
                    
                    // Contacts section
                    _buildSectionHeader(context, 'Kontak'),
                    ..._buildMenuItems(_menuSections['contacts']!, 'Kontak'),
                    
                    // Reports section
                    _buildSectionHeader(context, 'Laporan'),
                    ..._buildMenuItems(_menuSections['reports']!, 'Laporan'),
                    
                    // Settings section
                    _buildSectionHeader(context, 'Pengaturan'),
                    ..._buildMenuItems(_menuSections['settings']!, 'Pengaturan'),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24 + MediaQuery.of(context).padding.top,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF8e9aef)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(77), // 0.3 as alpha
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withAlpha(230), // 0.9 as alpha
                  child: Text(
                    widget.user?.name.isNotEmpty == true
                        ? widget.user!.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51), // 0.2 as alpha
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        widget.user?.role.toUpperCase() ?? 'Peran tidak diketahui',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51), // 0.2 as alpha
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.branch?.name ?? 'Cabang tidak diketahui',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 as alpha
            offset: const Offset(0, -3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26), // 0.1 as alpha
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 20,
              ),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: widget.onLogout,
            dense: true,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                const Text(
                  'MANUK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Versi 1.0.0',
                  style: TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '© 2025 MANUK - Manajemen Keuangan UMKM',
                  style: TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textMedium,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(List<DrawerMenuItem> items, String section) {
    return items.map((item) {
      final bool isSelected = _selectedIndex == item.hashCode;
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? AppTheme.primaryColor.withAlpha(26) : Colors.transparent, // 0.1 as alpha
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primaryColor.withAlpha(51) // 0.2 as alpha 
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppTheme.primaryColor.withAlpha(128)) // 0.5 as alpha
                    : null,
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textMedium,
              ),
            ),
            title: Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
              ),
            ),
            dense: true,
            visualDensity: const VisualDensity(vertical: -1),
            onTap: () {
              setState(() {
                _selectedIndex = item.hashCode;
              });
              Navigator.pop(context);
              Navigator.pushNamed(context, item.route);
            },
            trailing: isSelected
                ? Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                : null,
          ),
        ),
      );
    }).toList();
  }
}

class DrawerMenuItem {
  final IconData icon;
  final String title;
  final String route;
  
  DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });
  
  @override
  int get hashCode => route.hashCode;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrawerMenuItem && other.route == route;
  }
}