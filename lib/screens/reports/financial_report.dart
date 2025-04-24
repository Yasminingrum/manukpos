import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../models/transaction.dart';
import '../../models/expense.dart';
import '../../services/database_service.dart';
import '../../widgets/date_range_picker.dart';
import '../../widgets/export_button.dart';
import '../../widgets/report_summary_card.dart';

class FinancialReport extends StatefulWidget {
  const FinancialReport({super.key});

  @override
  State<FinancialReport> createState() => _FinancialReportState();
}

class _FinancialReportState extends State<FinancialReport> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseService _databaseService;
  
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  
  bool _isLoading = true;
  Map<String, dynamic> _financialSummary = {};
  List<Map<String, dynamic>> _cashFlowData = [];
  List<Expense> _expenses = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _databaseService = DatabaseService();
    _loadFinancialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get sales data for the selected period
      final salesData = await _getTransactionsByDateRange(
        _dateRange.start, 
        _dateRange.end,
      );
      
      // Get expenses data for the selected period
      final expenses = await _getExpensesByDateRange(
        _dateRange.start, 
        _dateRange.end,
      );
      
      // Get payment methods data
      final paymentMethods = await _getPaymentMethodsSummary(
        _dateRange.start,
        _dateRange.end,
      );
      
      // Get cash flow data for the selected period (daily)
      final cashFlowData = await _getCashFlowData(
        _dateRange.start,
        _dateRange.end,
      );
      
      // Calculate financial summary
      double totalRevenue = 0;
      double totalExpenses = 0;
      double totalProfit = 0;
      double totalTax = 0;
      
      for (var transaction in salesData) {
        totalRevenue += transaction.grandTotal;
        totalTax += transaction.taxAmount;
        // Use a method from the transaction model to calculate profit
        totalProfit += (transaction.subtotal - transaction.discountAmount);
      }
      
      for (var expense in expenses) {
        totalExpenses += expense.amount;
      }
      
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _paymentMethods = paymentMethods;
          _cashFlowData = cashFlowData;
          _financialSummary = {
            'totalRevenue': totalRevenue,
            'totalExpenses': totalExpenses,
            'totalProfit': totalProfit,
            'totalTax': totalTax,
            'netIncome': totalRevenue - totalExpenses,
            'profitMargin': totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading financial data: ${e.toString()}')),
        );
      }
    }
  }

  // Custom implementation for getting transactions by date range
  Future<List<Transaction>> _getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
      
      final transactions = await _databaseService.query(
        'transactions',
        where: 'transaction_date BETWEEN ? AND ? AND status != ?',
        whereArgs: [formattedStartDate, formattedEndDate, 'cancelled'],
        orderBy: 'transaction_date DESC',
      );
      
      // Convert maps to Transaction objects
      List<Transaction> result = [];
      for (var map in transactions) {
        // Get transaction items for each transaction
        final items = await _getTransactionItems(map['id'] as int);
        map['items'] = items;
        
        try {
          result.add(Transaction.fromMap(map));
        } catch (e) {
          if (kDebugMode) {
            print('Error creating Transaction from map: $e');
            print('Problematic map: $map');
          }
          // Continue with next item if one fails
          continue;
        }
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting transactions: $e');
      }
      return [];
    }
  }

  // Helper method to get transaction items
  Future<List<Map<String, dynamic>>> _getTransactionItems(int transactionId) async {
    try {
      return await _databaseService.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting transaction items: $e');
      }
      return [];
    }
  }

  // Custom implementation for getting expenses by date range
  Future<List<Expense>> _getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
      
      final expenses = await _databaseService.query(
        'expenses',
        where: 'expense_date BETWEEN ? AND ?',
        whereArgs: [formattedStartDate, formattedEndDate],
        orderBy: 'expense_date DESC',
      );
      
      // Convert maps to Expense objects
      List<Expense> result = [];
      for (var map in expenses) {
        try {
          result.add(Expense.fromMap(map));
        } catch (e) {
          if (kDebugMode) {
            print('Error creating Expense from map: $e');
            print('Problematic map: $map');
          }
          // Continue with next item if one fails
          continue;
        }
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting expenses: $e');
      }
      return [];
    }
  }

  // Custom implementation for getting payment methods summary
  Future<List<Map<String, dynamic>>> _getPaymentMethodsSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
      
      final db = await _databaseService.database;
      final List<Map<String,dynamic>> result = await db.rawQuery('''
        SELECT 
          payment_method,
          COUNT(*) as count,
          SUM(amount) as amount
        FROM payments
        WHERE payment_date BETWEEN ? AND ?
        GROUP BY payment_method
        ORDER BY amount DESC
      ''', [formattedStartDate, formattedEndDate]);
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment methods summary: $e');
      }
      return [];
    }
  }

  // Custom implementation for getting cash flow data
  Future<List<Map<String, dynamic>>> _getCashFlowData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));
      
      final db = await _databaseService.database;
      
      // Get daily income from transactions
      final List<Map<String, dynamic>> incomeData = await db.rawQuery('''
        SELECT 
          date(transaction_date) as date,
          SUM(grand_total) as income,
          COUNT(*) as transaction_count
        FROM transactions
        WHERE transaction_date BETWEEN ? AND ? AND status != 'cancelled'
        GROUP BY date(transaction_date)
        ORDER BY date(transaction_date)
      ''', [formattedStartDate, formattedEndDate]);
      
      // Get daily expenses
      final List<Map<String, dynamic>> expenseData = await db.rawQuery('''
        SELECT 
          date(expense_date) as date,
          SUM(amount) as expense
        FROM expenses
        WHERE expense_date BETWEEN ? AND ?
        GROUP BY date(expense_date)
        ORDER BY date(expense_date)
      ''', [formattedStartDate, formattedEndDate]);
      
      // Combine the data
      final Map<String, Map<String, dynamic>> dailyData = {};
      
      // Initialize with income data
      for (var row in incomeData) {
        final date = row['date'] as String;
        // Convert numeric values to double
        double income = 0.0;
        if (row['income'] != null) {
          income = (row['income'] is int) ? (row['income'] as int).toDouble() : (row['income'] as double);
        }
        
        dailyData[date] = {
          'date': date,
          'income': income,
          'expense': 0.0,
          'transactionCount': row['transaction_count'] as int? ?? 0,
        };
      }
      
      // Add expense data
      for (var row in expenseData) {
        final date = row['date'] as String;
        // Convert numeric values to double
        double expense = 0.0;
        if (row['expense'] != null) {
          expense = (row['expense'] is int) ? (row['expense'] as int).toDouble() : (row['expense'] as double);
        }
        
        if (dailyData.containsKey(date)) {
          dailyData[date]!['expense'] = expense;
        } else {
          dailyData[date] = {
            'date': date,
            'income': 0.0,
            'expense': expense,
            'transactionCount': 0,
          };
        }
      }
      
      // Convert to list and calculate net amount
      final List<Map<String, dynamic>> result = [];
      dailyData.forEach((date, data) {
        final double income = data['income'] as double;
        final double expense = data['expense'] as double;
        final int transactionCount = data['transactionCount'] as int;
        
        result.add({
          'date': date,
          'income': income,
          'expense': expense,
          'netAmount': income - expense,
          'transactionCount': transactionCount,
        });
      });
      
      // Sort by date
      result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cash flow data: $e');
      }
      return [];
    }
  }

  void _onDateRangeChanged(DateTime startDate, DateTime endDate) {
    setState(() {
      _dateRange = DateTimeRange(start: startDate, end: endDate);
    });
    _loadFinancialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          ExportButton(
            data: _generateExportData(),
            fileNamePrefix: 'laporan_keuangan',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Arus Kas'),
            Tab(text: 'Pengeluaran'),
            Tab(text: 'Metode Pembayaran'),
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
                    startDate: _dateRange.start,
                    endDate: _dateRange.end,
                    onDateRangeChanged: _onDateRangeChanged,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildCashFlowTab(),
                      _buildExpensesTab(),
                      _buildPaymentMethodsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Prepare data for export
  List<Map<String, dynamic>> _generateExportData() {
    // Convert financial summary to a list of maps for export
    final data = <Map<String, dynamic>>[];
    
    // Add summary data
    data.add({
      'title': 'Ringkasan Keuangan',
      'periode': '${DateFormat('dd MMM yyyy').format(_dateRange.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange.end)}',
      'total_pendapatan': _financialSummary['totalRevenue'] ?? 0,
      'total_pengeluaran': _financialSummary['totalExpenses'] ?? 0,
      'laba_bersih': _financialSummary['netIncome'] ?? 0,
      'total_pajak': _financialSummary['totalTax'] ?? 0,
    });
    
    return data;
  }

  Widget _buildSummaryTab() {
    final netIncome = _financialSummary['netIncome'] ?? 0;
    final profitMargin = _financialSummary['profitMargin'] ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ReportSummaryCard(
                  title: 'Total Pendapatan',
                  value: _currencyFormat.format(_financialSummary['totalRevenue'] ?? 0),
                  icon: Icons.arrow_circle_up,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ReportSummaryCard(
                  title: 'Total Pengeluaran',
                  value: _currencyFormat.format(_financialSummary['totalExpenses'] ?? 0),
                  icon: Icons.arrow_circle_down,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ReportSummaryCard(
                  title: 'Laba Bersih',
                  value: _currencyFormat.format(netIncome),
                  icon: Icons.account_balance,
                  color: netIncome >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ReportSummaryCard(
                  title: 'Margin Keuntungan',
                  value: '${profitMargin.toStringAsFixed(2)}%',
                  icon: Icons.percent,
                  color: profitMargin >= 20 ? Colors.green : 
                         profitMargin >= 10 ? Colors.amber : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ReportSummaryCard(
                  title: 'Total Laba Kotor',
                  value: _currencyFormat.format(_financialSummary['totalProfit'] ?? 0),
                  icon: Icons.trending_up,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ReportSummaryCard(
                  title: 'Total Pajak',
                  value: _currencyFormat.format(_financialSummary['totalTax'] ?? 0),
                  icon: Icons.receipt_long,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Ringkasan Pengeluaran Berdasarkan Kategori',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildExpenseCategoryChart(),
          const SizedBox(height: 24),
          const Text(
            'Ringkasan Penjualan Berdasarkan Waktu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSalesTimeChart(),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoryChart() {
    // Group expenses by category and calculate totals
    final Map<String, double> categoryTotals = {};
    for (var expense in _expenses) {
      final category = expense.category;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
    }
    
    // No data check
    if (categoryTotals.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text('Tidak ada data pengeluaran untuk periode ini'),
        ),
      );
    }
    
    // Prepare data for pie chart
    final List<MapEntry<String, double>> sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Simple pie chart implementation
    return SizedBox(
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    final total = categoryTotals.values.reduce((a, b) => a + b);
                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.primaries[index % Colors.primaries.length],
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(entry.key),
                      subtitle: Text(_currencyFormat.format(entry.value)),
                      trailing: Text('$percentage%'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesTimeChart() {
    // Get sales data by day of week
    final Map<String, double> salesByDayOfWeek = {
      'Senin': 0,
      'Selasa': 0,
      'Rabu': 0,
      'Kamis': 0,
      'Jumat': 0,
      'Sabtu': 0,
      'Minggu': 0,
    };
    
    // Populate sales data
    for (var data in _cashFlowData) {
      try {
        final date = DateTime.parse(data['date'] as String);
        final dayOfWeek = _getDayName(date.weekday);
        final income = data['income'] as double;
        
        salesByDayOfWeek[dayOfWeek] = (salesByDayOfWeek[dayOfWeek] ?? 0) + income;
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing date: $e');
        }
      }
    }
    
    // Simple bar chart implementation
    return SizedBox(
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: salesByDayOfWeek.length,
                  itemBuilder: (context, index) {
                    final entry = salesByDayOfWeek.entries.elementAt(index);
                    final maxValue = salesByDayOfWeek.values.reduce((a, b) => a > b ? a : b);
                    final percentage = maxValue > 0 ? entry.value / maxValue : 0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(entry.key),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 20,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percentage.toDouble(),
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Text(
                              _currencyFormat.format(entry.value),
                              textAlign: TextAlign.end,
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
      ),
    );
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Senin';
      case 2: return 'Selasa';
      case 3: return 'Rabu';
      case 4: return 'Kamis';
      case 5: return 'Jumat';
      case 6: return 'Sabtu';
      case 7: return 'Minggu';
      default: return '';
    }
  }

  Widget _buildCashFlowTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Arus Kas Harian',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: _buildCashFlowChart(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _cashFlowData.isEmpty
              ? const Center(child: Text('Tidak ada data arus kas untuk periode ini'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _cashFlowData.length,
                  itemBuilder: (context, index) {
                    final data = _cashFlowData[index];
                    final date = DateTime.parse(data['date'] as String);
                    final isPositive = (data['netAmount'] as double) >= 0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(
                          DateFormat('dd MMM yyyy (EEEE)').format(date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pemasukan: ${_currencyFormat.format(data['income'])}',
                              style: const TextStyle(color: Colors.green),
                            ),
                            Text(
                              'Pengeluaran: ${_currencyFormat.format(data['expense'])}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Net: ${_currencyFormat.format(data['netAmount'])}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              '${data['transactionCount']} transaksi',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                          child: Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                        onTap: () {
                          // Show detailed transactions for this day
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCashFlowChart() {
    if (_cashFlowData.isEmpty) {
      return const Center(child: Text('Tidak ada data untuk ditampilkan'));
    }

    // Prepare data for the chart
    // Get the last 14 days of data to avoid overcrowding
    final displayData = _cashFlowData.length > 14 
        ? _cashFlowData.sublist(_cashFlowData.length - 14) 
        : _cashFlowData;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    label: Text('Pemasukan'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Chip(
                    label: Text('Pengeluaran'),
                    backgroundColor: Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: displayData.length,
                itemBuilder: (context, index) {
                  final data = displayData[index];
                  final income = data['income'] as double;
                  final expense = data['expense'] as double;
                  
                  // Find max value for scaling
                  double maxValue = 0;
                  for (var data in displayData) {
                    final income = data['income'] as double;
                    final expense = data['expense'] as double;
                    maxValue = [maxValue, income, expense].reduce((curr, next) => curr > next ? curr : next);
                  }
                  
                  // Scale factor
                  final scale = maxValue > 0 ? 200 / maxValue : 0;
                  
                  // Format date for label
                  final date = DateTime.parse(data['date'] as String);
                  final dayLabel = DateFormat('dd/MM').format(date);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Income bar
                        Container(
                          width: 20,
                          height: income * scale,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 4),
                        // Expense bar
                        Container(
                          width: 20,
                          height: expense * scale,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 4),
                        Text(dayLabel, style: const TextStyle(fontSize: 10)),
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

  Widget _buildExpensesTab() {
    return _expenses.isEmpty
        ? const Center(child: Text('Tidak ada data pengeluaran untuk periode ini'))
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _expenses.length,
            itemBuilder: (context, index) {
              final expense = _expenses[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  title: Text(
                    expense.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(expense.expenseDate),
                      ),
                      Text(
                        'Kategori: ${expense.category}',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(expense.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      if (expense.referenceNumber != null)
                        Text(
                          'Ref: ${expense.referenceNumber}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: const Icon(
                      Icons.money_off,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    // Show expense details
                  },
                ),
              );
            },
          );
  }

  Widget _buildPaymentMethodsTab() {
    double totalPayments = 0;
    for (var method in _paymentMethods) {
      // Handle null value
      final methodAmount = method['amount'];
      double amount = 0.0;
      if (methodAmount != null) {
        amount = methodAmount is int ? methodAmount.toDouble() : methodAmount as double;
      }
      totalPayments += amount;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pembayaran Berdasarkan Metode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodsChart(totalPayments),
            ],
          ),
        ),
        Expanded(
          child: _paymentMethods.isEmpty
              ? const Center(child: Text('Tidak ada data metode pembayaran'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    // Handle null value
                    final methodAmount = method['amount'];
                    double amount = 0.0;
                    if (methodAmount != null) {
                      amount = methodAmount is int ? methodAmount.toDouble() : methodAmount as double;
                    }
                    
                    final percentage = totalPayments > 0 ? (amount / totalPayments) * 100 : 0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(
                          method['payment_method']?.toString() ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${method['count']} transaksi',
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currencyFormat.format(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: _getPaymentMethodIcon(method['payment_method']?.toString()),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsChart(double total) {
    if (_paymentMethods.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text('Tidak ada data metode pembayaran'),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _paymentMethods.length,
                  itemBuilder: (context, index) {
                    final method = _paymentMethods[index];
                    // Handle null value
                    final methodAmount = method['amount'];
                    double amount = 0.0;
                    if (methodAmount != null) {
                      amount = methodAmount is int ? methodAmount.toDouble() : methodAmount as double;
                    }
                    
                    final percentage = total > 0 ? (amount / total) * 100 : 0;
                    final methodName = method['payment_method']?.toString() ?? 'Unknown';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.primaries[index % Colors.primaries.length],
                            child: Text('${index + 1}', 
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: Text(methodName, overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 16,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percentage / 100,
                                  child: Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.primaries[index % Colors.primaries.length],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
      ),
    );
  }
  
  Icon _getPaymentMethodIcon(String? method) {
    if (method == null) {
      return const Icon(Icons.payment, color: Colors.blue);
    }
    
    switch (method.toLowerCase()) {
      case 'cash':
      case 'tunai':
        return const Icon(Icons.money, color: Colors.green);
      case 'credit card':
      case 'kartu kredit':
        return const Icon(Icons.credit_card, color: Colors.blue);
      case 'debit card':
      case 'kartu debit':
        return const Icon(Icons.credit_card, color: Colors.indigo);
      case 'transfer':
      case 'bank transfer':
        return const Icon(Icons.account_balance, color: Colors.purple);
      case 'qris':
        return const Icon(Icons.qr_code, color: Colors.orange);
      case 'e-wallet':
      case 'gopay':
      case 'ovo':
      case 'dana':
        return const Icon(Icons.account_balance_wallet, color: Colors.teal);
      default:
        return const Icon(Icons.payment, color: Colors.blue);
    }
  }
}