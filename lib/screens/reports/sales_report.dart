import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Using the database service
import '../../services/database_service.dart';
import '../../widgets/export_button.dart';
import '../../widgets/report_summary_card.dart';

class SalesReport extends StatefulWidget {
  const SalesReport({super.key});

  @override
  State<SalesReport> createState() => _SalesReportState();
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
        totalSales += transaction['grand_total'] as double? ?? 0.0;
        
        // Calculate profit based on items in transaction
        double transactionProfit = 0;
        List<dynamic> itemsList = transaction['items'] as List<dynamic>? ?? [];
        
        for (var item in itemsList) {
          Map<String, dynamic> itemMap = item as Map<String, dynamic>;
          double buyingPrice = itemMap['buying_price'] as double? ?? 0.0;
          double unitPrice = itemMap['unit_price'] as double? ?? 0.0;
          double quantity = itemMap['quantity'] is int ? 
            (itemMap['quantity'] as int).toDouble() : 
            itemMap['quantity'] as double? ?? 0.0;
            
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sales data: ${e.toString()}')),
        );
      }
    }
  }

  // Custom method to get transactions by date range
  Future<List<Map<String, dynamic>>> _getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Format dates for the query
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
      
      // Query the database for transactions within the date range
      final db = await _dbService.database;
      final List<Map<String, dynamic>> transactionMaps = await db.rawQuery('''
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
        final items = await _getTransactionItems(map['id'] as int);
        
        // Create a new map to avoid modifying the original
        final transaction = Map<String, dynamic>.from(map);
        transaction['items'] = items;
        
        result.add(transaction);
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }
  
  // Helper method to get transaction items
  Future<List<Map<String, dynamic>>> _getTransactionItems(int transactionId) async {
    try {
      final db = await _dbService.database;
      return await db.rawQuery('''
        SELECT ti.*, p.name as product_name, p.sku as product_sku, p.buying_price
        FROM transaction_items ti
        JOIN products p ON ti.product_id = p.id
        WHERE ti.transaction_id = ?
      ''', [transactionId]);
    } catch (e) {
      debugPrint('Error getting transaction items: $e');
      return [];
    }
  }

  // Custom method to get top selling products
  Future<List<Map<String, dynamic>>> _getTopSellingProducts(
    DateTime startDate,
    DateTime endDate,
    {int limit = 10}
  ) async {
    try {
      // Format dates for the query
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
      
      final db = await _dbService.database;
      return await db.rawQuery('''
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
    } catch (e) {
      debugPrint('Error getting top products: $e');
      return [];
    }
  }

  // Custom method to get sales by category
  Future<Map<String, double>> _getSalesByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Format dates for the query
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
      
      final db = await _dbService.database;
      final List<Map<String, dynamic>> results = await db.rawQuery('''
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
        final categoryName = result['category_name'] as String? ?? 'Unknown';
        final totalSales = result['totalSales'] as double? ?? 0.0;
        salesByCategory[categoryName] = totalSales;
      }
      
      return salesByCategory;
    } catch (e) {
      debugPrint('Error getting sales by category: $e');
      return {};
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
          ExportButton(
            data: _generateExportData(),
            fileNamePrefix: 'laporan_penjualan',
          ),
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

  // Generate data for export
  List<Map<String, dynamic>> _generateExportData() {
    final data = <Map<String, dynamic>>[];
    
    // Add summary data
    data.add({
      'title': 'Ringkasan Penjualan',
      'periode': '${DateFormat('dd MMM yyyy').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
      'total_penjualan': _salesSummary['totalSales'] ?? 0,
      'total_keuntungan': _salesSummary['totalProfit'] ?? 0,
      'total_transaksi': _salesSummary['totalTransactions'] ?? 0,
    });
    
    return data;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Group transactions by date
        Map<String, double> salesByDate = {};
        
        for (var transaction in _transactions) {
          if (transaction['transaction_date'] != null) {
            final dateStr = transaction['transaction_date'] as String;
            final date = DateTime.parse(dateStr);
            final dateKey = DateFormat('dd/MM').format(date);
            
            salesByDate[dateKey] = (salesByDate[dateKey] ?? 0) + 
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
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                          Text(_currencyFormat.format(maxValue), style: const TextStyle(fontSize: 10)),
                          Text(_currencyFormat.format(maxValue * 0.75), style: const TextStyle(fontSize: 10)),
                          Text(_currencyFormat.format(maxValue * 0.5), style: const TextStyle(fontSize: 10)),
                          Text(_currencyFormat.format(maxValue * 0.25), style: const TextStyle(fontSize: 10)),
                          const Text('0', style: TextStyle(fontSize: 10)),
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
                                Text(date, style: const TextStyle(fontSize: 10)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChart() {
    // Implement pie or bar chart for category breakdown
    if (_salesByCategory.isEmpty) {
      return const Center(child: Text('Tidak ada data kategori untuk ditampilkan'));
    }
    
    // Sort categories by sales amount
    final List<MapEntry<String, double>> sortedEntries = _salesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate total for percentages
    final double totalSales = _salesByCategory.values.reduce((a, b) => a + b);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final category = entry.key;
                  final amount = entry.value;
                  final percentage = totalSales > 0 ? (amount / totalSales * 100) : 0;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.primaries[index % Colors.primaries.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          _currencyFormat.format(amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
              final totalSold = product['totalSold'] is int ? 
                product['totalSold'] as int : 
                (product['totalSold'] as double?)?.toInt() ?? 0;
                
              final totalRevenue = product['totalRevenue'] as double? ?? 0.0;
              
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
                        'Terjual: $totalSold',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _currencyFormat.format(totalRevenue),
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
              final items = transaction['items'] as List<dynamic>? ?? [];
              
              String? invoiceNumber = transaction['invoice_number'] as String?;
              double grandTotal = transaction['grand_total'] as double? ?? 0.0;
              
              String? transactionDateStr = transaction['transaction_date'] as String?;
              DateTime? transactionDate;
              if (transactionDateStr != null) {
                try {
                  transactionDate = DateTime.parse(transactionDateStr);
                } catch (e) {
                  debugPrint('Error parsing date: $e');
                }
              }
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  title: Text(
                    'Invoice #${invoiceNumber ?? 'Unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (transactionDate != null)
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(transactionDate),
                        ),
                      Text(
                        'Kasir: ${transaction['user_name'] ?? 'Unknown'}',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(grandTotal),
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
                    _showTransactionDetails(transaction);
                  },
                ),
              );
            },
          );
  }
  
  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final items = transaction['items'] as List<dynamic>? ?? [];
        
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Invoice #${transaction['invoice_number'] ?? 'Unknown'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tanggal: ${transaction['transaction_date'] != null ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(transaction['transaction_date'])) : 'Unknown'}',
                  ),
                  Text('Kasir: ${transaction['user_name'] ?? 'Unknown'}'),
                  if (transaction['customer_name'] != null)
                    Text('Pelanggan: ${transaction['customer_name']}'),
                  const Divider(height: 24),
                  const Text(
                    'Item Transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index] as Map<String, dynamic>;
                        
                        final quantity = item['quantity'] is int ? 
                          (item['quantity'] as int).toDouble() : 
                          (item['quantity'] as double? ?? 0.0);
                          
                        final unitPrice = item['unit_price'] as double? ?? 0.0;
                        final subtotal = quantity * unitPrice;
                        
                        return ListTile(
                          title: Text(item['product_name'] ?? 'Unknown Product'),
                          subtitle: Text('${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} x ${_currencyFormat.format(unitPrice)}'),
                          trailing: Text(
                            _currencyFormat.format(subtotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(transaction['grand_total'] ?? 0),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}