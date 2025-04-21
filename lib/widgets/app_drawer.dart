import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String? currentRoute;
  
  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/dashboard',
                  isSelected: currentRoute == '/dashboard',
                ),
                _buildExpandableSection(
                  context,
                  icon: Icons.point_of_sale,
                  title: 'Transaksi',
                  children: [
                    _buildSubDrawerItem(
                      context,
                      title: 'Kasir POS',
                      route: '/transactions/pos',
                      isSelected: currentRoute == '/transactions/pos',
                    ),
                    _buildSubDrawerItem(
                      context,
                      title: 'Pembelian Barang',
                      route: '/transactions/purchasing',
                      isSelected: currentRoute == '/transactions/purchasing',
                    ),
                    _buildSubDrawerItem(
                      context,
                      title: 'Riwayat Transaksi',
                      route: '/transactions/history',
                      isSelected: currentRoute == '/transactions/history',
                    ),
                  ],
                ),
                _buildExpandableSection(
                  context,
                  icon: Icons.inventory,
                  title: 'Manajemen Inventori',
                  children: [
                    _buildSubDrawerItem(
                      context,
                      title: 'Daftar Produk',
                      route: '/inventory/products',
                      isSelected: currentRoute == '/inventory/products',
                    ),
                    _buildSubDrawerItem(
                      context,
                      title: 'Stock Opname',
                      route: '/inventory/stock-opname',
                      isSelected: currentRoute == '/inventory/stock-opname',
                    ),
                  ],
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.payment,
                  title: 'Pembayaran',
                  route: '/payments',
                  isSelected: currentRoute == '/payments',
                ),
                _buildExpandableSection(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Laporan',
                  children: [
                    _buildSubDrawerItem(
                      context,
                      title: 'Laporan Penjualan',
                      route: '/reports/sales',
                      isSelected: currentRoute == '/reports/sales',
                    ),
                    _buildSubDrawerItem(
                      context,
                      title: 'Laporan Stok',
                      route: '/reports/inventory',
                      isSelected: currentRoute == '/reports/inventory',
                    ),
                    _buildSubDrawerItem(
                      context,
                      title: 'Laporan Produk',
                      route: '/reports/products',
                      isSelected: currentRoute == '/reports/products',
                    ),
                  ],
                ),
                _buildExpandableSection(
                  context,
                  icon: Icons.people,
                  title: 'Database',
                  children: [
                    _buildSubDrawerItem(
                      context,
                      title: 'Pelanggan',
                      route: '/database/customers',
                      isSelected: currentRoute == '/database/customers',
                    ),
                    _buildSubDrawerItem(
                      context,
                      title: 'Supplier',
                      route: '/database/suppliers',
                      isSelected: currentRoute == '/database/suppliers',
                    ),
                    _buildSubDrawerItem(
                      context,
                      title: 'Kategori Produk',
                      route: '/database/categories',
                      isSelected: currentRoute == '/database/categories',
                    ),
                  ],
                ),
                _buildExpandableSection(
                  context,
                  icon: Icons.settings,
                  title: 'Pengaturan',
                  children: [
                    _buildSubDrawerItem(
                      context,
                      title: 'Profil Bisnis',
                      route: '/settings/business',
                      isSelected: currentRoute == '/settings/business',
                    ),
                    _buildSubDrawerItem(
                      context,
                      title: 'Pengguna & Hak Akses',
                      route: '/settings/users',
                      isSelected: currentRoute == '/settings/users',
                    ),
                    _buildSubDrawerItem(
                      context,
                      title: 'Preferensi Aplikasi',
                      route: '/settings/preferences',
                      isSelected: currentRoute == '/settings/preferences',
                    ),
                  ],
                ),
                Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Keluar',
                  onTap: () => _handleLogout(context),
                ),
              ],
            ),
          ),
          _buildVersionInfo(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo or profile avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              'M',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Business name
          const Text(
            'MANUK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Manajemen Keuangan UMKM',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final color = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyLarge?.color;
    
    final background = isSelected
        ? Theme.of(context).primaryColor.withOpacity(0.1)
        : Colors.transparent;

    return Container(
      color: background,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(color: color),
        ),
        onTap: onTap ??
            () {
              if (route != null) {
                // Close the drawer first
                Navigator.of(context).pop();
                // Navigate to the selected route
                Navigator.of(context).pushReplacementNamed(route);
              }
            },
      ),
    );
  }

  Widget _buildSubDrawerItem(
    BuildContext context, {
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    final color = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyLarge?.color;
    
    final background = isSelected
        ? Theme.of(context).primaryColor.withOpacity(0.1)
        : Colors.transparent;

    return Container(
      color: background,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 50.0, right: 16.0),
        title: Text(
          title,
          style: TextStyle(color: color),
        ),
        onTap: () {
          // Close the drawer first
          Navigator.of(context).pop();
          // Navigate to the selected route
          Navigator.of(context).pushReplacementNamed(route);
        },
      ),
    );
  }

  Widget _buildExpandableSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      children: children,
    );
  }

  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'MANUK POS v1.0.0',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("BATAL"),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement logout logic with your auth service
              // AuthService().signOut().then((_) {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed('/login');
              // });
            },
            child: const Text("KELUAR"),
          ),
        ],
      ),
    );
  }
}