import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../widgets/date_range_picker.dart';
import '../../widgets/export_button.dart';
import '../../widgets/report_summary_card.dart';
import '../../widgets/sales_chart.dart';

class SalesReport extends StatefulWidget {
  const SalesReport({super.key});

  @override
  _SalesReportState createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  
  bool _isLoading = true;
  List<Transaction> _transactions = [];
  Map<String, dynamic> _salesSummary = {};
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, double> _salesByCategory = {};

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSalesData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get transactions for the selected date range
      final transactions = await DatabaseService.getTransactionsByDateRange(
        _dateRange.start, 
        _dateRange.end
      );
      
      // Calculate sales summary
      double totalSales = 0;
      double totalProfit = 0;
      int totalTransactions = transactions.length;
      
      for (var transaction in transactions) {
        totalSales += transaction.grandTotal;
        totalProfit += transaction.calculateProfit();
      }
      
      // Get top products
      final topProducts = await DatabaseService.getTopSellingProducts(
        _dateRange.start,
        _dateRange.end,
        limit: 10,
      );
      
      // Get sales by category
      final salesByCategory = await DatabaseService.getSalesByCategory(
        _dateRange.start,
        _dateRange.end,
      );
      
      setState(() {
        _transactions = transactions;
        _salesSummary = {
          'totalSales': totalSales,
          'totalProfit': totalProfit,
          'totalTransactions': totalTransactions,
          'averageTransaction': totalTransactions > 0 ? totalSales / totalTransactions : 0,
        };
        _topProducts = topProducts;
        _salesByCategory = Map<String, double>.from(salesByCategory);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sales data: ${e.toString()}')),
      );
    }
  }

  void _onDateRangeChanged(DateTimeRange newRange) {
    setState(() {
      _dateRange = newRange;
    });
    _loadSalesData();
  }

  void _exportReport() {
    // Implement export functionality (CSV, PDF, etc)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting sales report...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          ExportButton(onPressed: _exportReport),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Produk Terlaris'),
            Tab(text: 'Detail Transaksi'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DateRangePicker(
                    initialDateRange: _dateRange,
                    onDateRangeChanged: _onDateRangeChanged,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildTopProductsTab(),
                      _buildTransactionsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ReportSummaryCard(
                  title: 'Total Penjualan',
                  value: _currencyFormat.format(_salesSummary['totalSales'] ?? 0),
                  icon: Icons.monetization_on,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ReportSummaryCard(
                  title: 'Total Keuntungan',
                  value: _currencyFormat.format(_salesSummary['totalProfit'] ?? 0),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ReportSummaryCard(
                  title: 'Jumlah Transaksi',
                  value: '${_salesSummary['totalTransactions'] ?? 0}',
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ReportSummaryCard(
                  title: 'Rata-rata Transaksi',
                  value: _currencyFormat.format(_salesSummary['averageTransaction'] ?? 0),
                  icon: Icons.equalizer,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Tren Penjualan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: SalesChart(
              transactions: _transactions,
              dateRange: _dateRange,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Penjualan per Kategori',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: _buildCategoryChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    // Implement pie or bar chart for category breakdown
    return Center(
      child: Text('Grafik Kategori akan ditampilkan di sini'),
    );
  }

  Widget _buildTopProductsTab() {
    return _topProducts.isEmpty
        ? const Center(child: Text('Tidak ada data produk terlaris'))
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _topProducts.length,
            itemBuilder: (context, index) {
              final product = _topProducts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(product['name'] ?? 'Unnamed Product'),
                  subtitle: Text('SKU: ${product['sku'] ?? 'N/A'}'),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Terjual: ${product['totalSold']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currencyFormat.format(product['totalRevenue'] ?? 0),
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildTransactionsTab() {
    return _transactions.isEmpty
        ? const Center(child: Text('Tidak ada transaksi pada rentang waktu ini'))
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  title: Text(
                    'Invoice #${transaction.invoiceNumber}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(transaction.transactionDate),
                      ),
                      Text(
                        'Kasir: ${transaction.userName}',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(transaction.grandTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${transaction.items.length} item',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Show transaction details
                  },
                ),
              );
            },
          );
  }
}