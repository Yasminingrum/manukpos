// screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../config/constants.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/recent_transaction_item.dart';
import '../../widgets/custom_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  // Dashboard data
  double totalSalesToday = 0;
  int transactionCountToday = 0;
  double averageTransactionValue = 0;
  List<Map<String, dynamic>> recentTransactions = [];
  List<Map<String, dynamic>> lowStockProducts = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // Load dashboard data from database
  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final database = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final branchId = authService.currentBranch?.id;

      if (branchId == null) {
        // Handle case when branch is not selected
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Format date for query
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final dateString = dateFormatter.format(selectedDate);
      
      // Get sales data for today
      final salesQuery = '''
        SELECT SUM(grand_total) as total_sales, COUNT(id) as transaction_count
        FROM ${AppConstants.tableTransactions}
        WHERE DATE(transaction_date) = '$dateString'
        AND branch_id = $branchId
        AND status = 'completed'
      ''';
      
      final salesResult = await database.rawQuery(salesQuery);
      
      if (salesResult.isNotEmpty) {
        totalSalesToday = salesResult.first['total_sales'] as double? ?? 0;
        transactionCountToday = salesResult.first['transaction_count'] as int? ?? 0;
        
        if (transactionCountToday > 0) {
          averageTransactionValue = totalSalesToday / transactionCountToday;
        }
      }
      
      // Get recent transactions
      final recentTransactionsQuery = '''
        SELECT t.id, t.invoice_number, t.transaction_date, t.grand_total, 
               c.name as customer_name, t.payment_status
        FROM ${AppConstants.tableTransactions} t
        LEFT JOIN ${AppConstants.tableCustomers} c ON t.customer_id = c.id
        WHERE t.branch_id = $branchId
        ORDER BY t.transaction_date DESC
        LIMIT 5
      ''';
      
      recentTransactions = await database.rawQuery(recentTransactionsQuery);
      
      // Get low stock products
      final lowStockQuery = '''
        SELECT p.id, p.name, p.sku, i.quantity, p.min_stock
        FROM ${AppConstants.tableProducts} p
        JOIN ${AppConstants.tableInventory} i ON p.id = i.product_id
        WHERE i.branch_id = $branchId
        AND i.quantity <= p.min_stock
        AND p.is_active = 1
        AND p.is_service = 0
        ORDER BY (i.quantity / p.min_stock) ASC
        LIMIT 5
      ''';
      
      lowStockProducts = await database.rawQuery(lowStockQuery);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Change selected date
  void _onDateChanged(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    _loadDashboardData();
  }
  
  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != selectedDate) {
      _onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final branch = authService.currentBranch;
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Pilih Tanggal',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: CustomDrawer(
        user: user,
        branch: branch,
        onLogout: () async {
          await authService.logout();
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRouter.login);
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with branch and date info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cabang: ${branch?.name ?? 'Tidak Diketahui'}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kasir: ${user?.name ?? 'Tidak Diketahui'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('EEEE', 'id_ID').format(selectedDate),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d MMMM yyyy', 'id_ID').format(selectedDate),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sales summary cards
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Total Penjualan',
                            value: currencyFormat.format(totalSalesToday),
                            icon: Icons.attach_money,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            title: 'Jumlah Transaksi',
                            value: transactionCountToday.toString(),
                            icon: Icons.receipt_long,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Rata-rata Transaksi',
                            value: currencyFormat.format(averageTransactionValue),
                            icon: Icons.trending_up,
                            color: AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            title: 'Stok Menipis',
                            value: lowStockProducts.length.toString(),
                            icon: Icons.warning_amber,
                            color: lowStockProducts.isEmpty ? AppTheme.successColor : AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Action Buttons
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aksi Cepat',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildQuickActionButton(
                                  context,
                                  icon: Icons.point_of_sale,
                                  label: 'POS',
                                  onTap: () => Navigator.pushNamed(context, AppRouter.pos),
                                ),
                                _buildQuickActionButton(
                                  context,
                                  icon: Icons.inventory,
                                  label: 'Produk',
                                  onTap: () => Navigator.pushNamed(context, AppRouter.products),
                                ),
                                _buildQuickActionButton(
                                  context,
                                  icon: Icons.shopping_cart,
                                  label: 'Pembelian',
                                  onTap: () => Navigator.pushNamed(context, AppRouter.purchasing),
                                ),
                                _buildQuickActionButton(
                                  context,
                                  icon: Icons.people,
                                  label: 'Pelanggan',
                                  onTap: () => Navigator.pushNamed(context, AppRouter.customers),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Transactions Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Transaksi Terbaru',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, AppRouter.transactionHistory),
                                  child: const Text('Lihat Semua'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (recentTransactions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text('Belum ada transaksi'),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentTransactions.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final transaction = recentTransactions[index];
                                  return RecentTransactionItem(
                                    invoice: transaction['invoice_number'] as String,
                                    date: DateTime.parse(transaction['transaction_date'] as String),
                                    amount: transaction['grand_total'] as double,
                                    customerName: transaction['customer_name'] as String? ?? 'Umum',
                                    status: transaction['payment_status'] as String,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.transactionDetail,
                                      arguments: transaction['id'] as int,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Low Stock Products Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Produk Stok Menipis',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, AppRouter.stockOpname),
                                  child: const Text('Kelola Stok'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (lowStockProducts.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text('Semua stok produk masih mencukupi'),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: lowStockProducts.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final product = lowStockProducts[index];
                                  final quantity = product['quantity'] as double;
                                  final minStock = product['min_stock'] as int;
                                  
                                  return ListTile(
                                    title: Text(
                                      product['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('SKU: ${product['sku']}'),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Sisa: ${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1)}',
                                          style: TextStyle(
                                            color: quantity <= 0 ? AppTheme.errorColor : AppTheme.warningColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text('Min: $minStock'),
                                      ],
                                    ),
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.productDetail,
                                      arguments: product['id'] as int,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.pos),
        icon: const Icon(Icons.point_of_sale),
        label: const Text('Transaksi Baru'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }
  
  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}