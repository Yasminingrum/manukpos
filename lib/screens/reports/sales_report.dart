import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Using the database service
import '../../services/database_service.dart' show DatabaseService;
import '../../widgets/export_button.dart';
import '../../widgets/report_summary_card.dart';

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
  List<Map<String, dynamic>> _transactions = []; // Changed from Transaction objects to Map
  Map<String, dynamic> _salesSummary = {};
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, double> _salesByCategory = {};
  final DatabaseService _dbService = DatabaseService();

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
      final transactions = await _getTransactionsByDateRange(
        _dateRange.start, 
        _dateRange.end
      );
      
      // Calculate sales summary
      double totalSales = 0;
      double totalProfit = 0;
      int totalTransactions = transactions.length;
      
      for (var transaction in transactions) {
        totalSales += transaction['grand_total'] as double;
        // Calculate profit based on items in transaction
        double transactionProfit = 0;
        List<Map<String, dynamic>> items = transaction['items'] as List<Map<String, dynamic>>;
        for (var item in items) {
          double buyingPrice = item['buying_price'] as double;
          double unitPrice = item['unit_price'] as double;
          double quantity = item['quantity'] as double;
          transactionProfit += (unitPrice - buyingPrice) * quantity;
        }
        totalProfit += transactionProfit;
      }
      
      // Get top products
      final topProducts = await _getTopSellingProducts(
        _dateRange.start,
        _dateRange.end,
      );
      
      // Get sales by category
      final salesByCategory = await _getSalesByCategory(
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

  // Custom method to get transactions by date range
  Future<List<Map<String, dynamic>>> _getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Format dates to ISO strings for the query
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    // Query the database for transactions within the date range
    final List<Map<String, dynamic>> transactionMaps = await _dbService.rawQuery('''
      SELECT t.*, u.name as user_name, c.name as customer_name
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.transaction_date BETWEEN ? AND ?
      ORDER BY t.transaction_date DESC
    ''', [startDateStr, endDateStr]);
    
    // Get transaction items for each transaction
    List<Map<String, dynamic>> result = [];
    for (var map in transactionMaps) {
      // Get items for this transaction
      final items = await _getTransactionItems(map['id']);
      
      // Add items to transaction map instead of creating Transaction object
      map['items'] = items;
      
      result.add(map);
    }
    
    return result;
  }
  
  // Helper method to get transaction items
  Future<List<Map<String, dynamic>>> _getTransactionItems(int transactionId) async {
    return await _dbService.rawQuery('''
      SELECT ti.*, p.name as product_name, p.sku as product_sku, p.buying_price
      FROM transaction_items ti
      JOIN products p ON ti.product_id = p.id
      WHERE ti.transaction_id = ?
    ''', [transactionId]);
  }

  // Custom method to get top selling products
  Future<List<Map<String, dynamic>>> _getTopSellingProducts(
    DateTime startDate,
    DateTime endDate,
    {int limit = 10}
  ) async {
    // Format dates to ISO strings for the query
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    return await _dbService.rawQuery('''
      SELECT 
        p.id, 
        p.name, 
        p.sku,
        SUM(ti.quantity) as totalSold,
        SUM(ti.quantity * ti.unit_price) as totalRevenue,
        SUM(ti.quantity * (ti.unit_price - p.buying_price)) as totalProfit
      FROM transaction_items ti
      JOIN products p ON ti.product_id = p.id
      JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.transaction_date BETWEEN ? AND ?
      GROUP BY p.id
      ORDER BY totalSold DESC
      LIMIT ?
    ''', [startDateStr, endDateStr, limit]);
  }

  // Custom method to get sales by category
  Future<Map<String, double>> _getSalesByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Format dates to ISO strings for the query
    final startDateStr = startDate.toIso8601String();
    final endDateStr = endDate.toIso8601String();
    
    final List<Map<String, dynamic>> results = await _dbService.rawQuery('''
      SELECT 
        c.name as category_name,
        SUM(ti.quantity * ti.unit_price) as totalSales
      FROM transaction_items ti
      JOIN products p ON ti.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.transaction_date BETWEEN ? AND ?
      GROUP BY c.id
      ORDER BY totalSales DESC
    ''', [startDateStr, endDateStr]);
    
    // Convert to Map<String, double>
    Map<String, double> salesByCategory = {};
    for (var result in results) {
      salesByCategory[result['category_name']] = result['totalSales'];
    }
    
    return salesByCategory;
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
      body: Builder(
        builder: (BuildContext context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDateRangePicker(),
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
            );
          }
        },
      ),
    );
  }
  
  // Custom date range picker widget
  Widget _buildDateRangePicker() {
    // Simplified date range picker without using external widget
    return InkWell(
      onTap: () => _selectDateRange(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${DateFormat('dd MMM yyyy').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
              style: const TextStyle(fontSize: 14),
            ),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _dateRange) {
      _onDateRangeChanged(picked);
    }
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
          if (_transactions.isNotEmpty)
            SizedBox(
              height: 300,
              child: _buildSalesChart(),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Tidak ada data transaksi untuk ditampilkan'),
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
  
  // Custom sales chart widget
  Widget _buildSalesChart() {
    // Create a simple bar chart as a placeholder
    // This replaces the SalesChart component to avoid parameter issues
    return LayoutBuilder(
      builder: (context, constraints) {
        // Group transactions by date
        Map<String, double> salesByDate = {};
        
        for (var transaction in _transactions) {
          if (transaction['transaction_date'] != null) {
            final date = DateTime.parse(transaction['transaction_date']);
            final dateStr = DateFormat('dd/MM').format(date);
            
            salesByDate[dateStr] = (salesByDate[dateStr] ?? 0) + 
                (transaction['grand_total'] as double? ?? 0);
          }
        }
        
        if (salesByDate.isEmpty) {
          return const Center(child: Text('Tidak ada data untuk ditampilkan'));
        }
        
        // Sort dates
        final sortedDates = salesByDate.keys.toList()
          ..sort((a, b) {
            final dateA = DateFormat('dd/MM').parse(a);
            final dateB = DateFormat('dd/MM').parse(b);
            return dateA.compareTo(dateB);
          });
        
        // Calculate max value for scaling
        final maxValue = salesByDate.values.reduce((a, b) => a > b ? a : b);
        
        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Y-axis labels
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_currencyFormat.format(maxValue), style: TextStyle(fontSize: 10)),
                      Text(_currencyFormat.format(maxValue * 0.75), style: TextStyle(fontSize: 10)),
                      Text(_currencyFormat.format(maxValue * 0.5), style: TextStyle(fontSize: 10)),
                      Text(_currencyFormat.format(maxValue * 0.25), style: TextStyle(fontSize: 10)),
                      Text('0', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Bars
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: sortedDates.map((date) {
                        final value = salesByDate[date] ?? 0;
                        final percentage = maxValue > 0 ? value / maxValue : 0;
                        
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 20,
                              height: constraints.maxHeight * 0.8 * percentage,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 4),
                            Text(date, style: TextStyle(fontSize: 10)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChart() {
    // Implement pie or bar chart for category breakdown
    return _salesByCategory.isEmpty
        ? const Center(child: Text('Tidak ada data kategori untuk ditampilkan'))
        : Center(
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currencyFormat.format(product['totalRevenue'] ?? 0),
                        style: const TextStyle(color: Colors.green),
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
              final items = transaction['items'] as List<Map<String, dynamic>>;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  title: Text(
                    'Invoice #${transaction['invoice_number']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (transaction['transaction_date'] != null)
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(
                            DateTime.parse(transaction['transaction_date'])
                          ),
                        ),
                      Text(
                        'Kasir: ${transaction['user_name']}',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(transaction['grand_total'] ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${items.length} item',
                        style: const TextStyle(fontSize: 12),
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