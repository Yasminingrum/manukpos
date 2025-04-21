// widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/user.dart';
import '../models/branch.dart';

class CustomDrawer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, AppRouter.dashboard);
                  },
                ),
                const Divider(),
                _buildSectionHeader(context, 'Transaksi'),
                _buildDrawerItem(
                  context,
                  icon: Icons.point_of_sale,
                  title: 'Kasir (POS)',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.pos);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.shopping_cart,
                  title: 'Pembelian',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.purchasing);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Riwayat Transaksi',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.transactionHistory);
                  },
                ),
                const Divider(),
                _buildSectionHeader(context, 'Inventori'),
                _buildDrawerItem(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Produk',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.products);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.category,
                  title: 'Kategori',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.categories);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assessment,
                  title: 'Stock Opname',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.stockOpname);
                  },
                ),
                const Divider(),
                _buildSectionHeader(context, 'Kontak'),
                _buildDrawerItem(
                  context,
                  icon: Icons.people,
                  title: 'Pelanggan',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.customers);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.local_shipping,
                  title: 'Supplier',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.suppliers);
                  },
                ),
                const Divider(),
                _buildSectionHeader(context, 'Laporan'),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Laporan Penjualan',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.salesReport);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.inventory,
                  title: 'Laporan Inventori',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.inventoryReport);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.account_balance_wallet,
                  title: 'Laporan Keuangan',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.financialReport);
                  },
                ),
                const Divider(),
                _buildSectionHeader(context, 'Pengaturan'),
                _buildDrawerItem(
                  context,
                  icon: Icons.business,
                  title: 'Profil Bisnis',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.businessProfile);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_alt,
                  title: 'Pengguna',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.userManagement);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Pengaturan Aplikasi',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRouter.appSettings);
                  },
                ),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24 + MediaQuery.of(context).padding.top,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      color: AppTheme.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              user?.name.isNotEmpty == true
                  ? user!.name.substring(0, 1).toUpperCase()
                  : 'U',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.role.toUpperCase() ?? 'Peran tidak diketahui',
            style: TextStyle(
              color: Colors.white.withAlpha(204), // Changed from withOpacity(0.8)
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.store,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  branch?.name ?? 'Cabang tidak diketahui',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204), // Changed from withOpacity(0.8)
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                const Text(
                  'MANUK', // Added constant value directly
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Versi 1.0.0', // Added constant value directly
                  style: TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '© 2025 MANUK - Manajemen Keuangan UMKM', // Added constant value directly
                  style: TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                  ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.textMedium,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      dense: true,
      onTap: onTap,
    );
  }
}