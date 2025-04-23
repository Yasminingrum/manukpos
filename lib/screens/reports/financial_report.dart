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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
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
      return transactions.map((map) => Transaction.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting transactions: $e');
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
      return expenses.map((map) => Expense.fromMap(map)).toList();
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
      
      final List<Map<String,dynamic>> result = await _databaseService.rawQuery('''
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
      
      // Get daily income from transactions
      final List<Map<String, dynamic>> incomeData = await _databaseService.rawQuery('''
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
      final List<Map<String, dynamic>> expenseData = await _databaseService.rawQuery('''
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
        dailyData[date] = {
          'date': date,
          'income': row['income'] as double? ?? 0.0,
          'expense': 0.0,
          'transactionCount': row['transaction_count'] as int? ?? 0,
        };
      }
      
      // Add expense data
      for (var row in expenseData) {
        final date = row['date'] as String;
        if (dailyData.containsKey(date)) {
          dailyData[date]!['expense'] = row['expense'] as double? ?? 0.0;
        } else {
          dailyData[date] = {
            'date': date,
            'income': 0.0,
            'expense': row['expense'] as double? ?? 0.0,
            'transactionCount': 0,
          };
        }
      }
      
      // Convert to list and calculate net amount
      final List<Map<String, dynamic>> result = [];
      dailyData.forEach((date, data) {
        final double income = data['income'] as double? ?? 0.0;
        final double expense = data['expense'] as double? ?? 0.0;
        final int transactionCount = data['transactionCount'] as int? ?? 0;
        
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
            data: _financialSummary,
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
    // Implement pie chart for expense categories
    return const SizedBox(
      height: 250,
      child: Center(
        child: Text('Grafik Kategori Pengeluaran akan ditampilkan di sini'),
      ),
    );
  }

  Widget _buildSalesTimeChart() {
    // Implement bar or line chart for sales by time (day of week, hour, etc)
    return const SizedBox(
      height: 250,
      child: Center(
        child: Text('Grafik Penjualan Berdasarkan Waktu akan ditampilkan di sini'),
      ),
    );
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
                    final isPositive = (data['netAmount'] as num) >= 0;
                    
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
    // Simple placeholder for the cash flow chart
    return const Center(
      child: Text('Chart will be displayed here'),
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
      totalPayments += (method['amount'] as num?)?.toDouble() ?? 0;
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
                    final amount = (method['amount'] as num?)?.toDouble() ?? 0;
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
    // Implement pie chart for payment methods
    return const SizedBox(
      height: 250,
      child: Center(
        child: Text('Grafik Metode Pembayaran akan ditampilkan di sini'),
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