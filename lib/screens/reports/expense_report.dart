// screens/reports/expense_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../services/expense_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/date_range_picker.dart';
import '../../widgets/export_button.dart';
import '../../widgets/report_summary_card.dart';
import '../../widgets/cash_flow_chart.dart';

class ExpenseReportScreen extends StatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  // Default date range - current month
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  
  List<Expense> _expenses = [];
  Map<String, dynamic> _expenseSummary = {};
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filters
  String? _selectedCategory;
  List<String> _categories = [];
  
  // For pagination
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  
  late ExpenseService _expenseService;
  late AuthService _authService;
  
  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    await _loadCategories();
    await _loadExpenses(refresh: true);
    await _loadExpenseSummary();
  }
  
  Future<void> _loadCategories() async {
    try {
      final categories = await _expenseService.getExpenseCategories(
        token: _authService.token,
      );
      
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }
  
  Future<void> _loadExpenses({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
        _errorMessage = null;
      });
    } else if (!_hasMoreData) {
      return;
    }
    
    try {
      final expenses = await _expenseService.getExpenses(
        startDate: _startDate,
        endDate: _endDate,
        category: _selectedCategory,
        branchId: _authService.currentBranch?.id,
        page: _currentPage,
        limit: _pageSize,
        token: _authService.token,
      );
      
      setState(() {
        if (refresh) {
          _expenses = expenses;
        } else {
          _expenses = [..._expenses, ...expenses];
        }
        
        _isLoading = false;
        _hasMoreData = expenses.length >= _pageSize;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading expenses: $e';
      });
    }
  }
  
  Future<void> _loadExpenseSummary() async {
    try {
      final summary = await _expenseService.getExpenseSummary(
        startDate: _startDate,
        endDate: _endDate,
        branchId: _authService.currentBranch?.id,
        token: _authService.token,
      );
      
      setState(() {
        _expenseSummary = summary;
      });
    } catch (e) {
      print('Error loading expense summary: $e');
    }
  }
  
  void _onDateRangeChanged(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });
    
    _loadExpenses(refresh: true);
    _loadExpenseSummary();
  }
  
  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    
    _loadExpenses(refresh: true);
  }
  
  void _exportReport() async {
    // Additional export functionality could be implemented here
    // Currently handled by the ExportButton widget
  }
  
  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenseSummary['total_amount'] ?? 0.0;
    final expenseCount = _expenseSummary['count'] ?? 0;
    final categoryData = _expenseSummary['by_category'] as Map<String, dynamic>? ?? {};
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Report'),
        actions: [
          ExportButton<Expense>(
            data: _expenses,
            fileNamePrefix: 'expense_report',
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : RefreshIndicator(
              onRefresh: () => _loadExpenses(refresh: true),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range picker
                    DateRangePicker(
                      startDate: _startDate,
                      endDate: _endDate,
                      onDateRangeChanged: _onDateRangeChanged,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category filter
                    _buildCategoryFilter(),
                    
                    const SizedBox(height: 16),
                    
                    // Summary cards
                    Row(
                      children: [
                        Expanded(
                          child: ReportSummaryCard(
                            title: 'Total Expenses',
                            value: 'Rp ${NumberFormat('#,###').format(totalExpenses)}',
                            icon: Icons.money_off,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ReportSummaryCard(
                            title: 'Number of Expenses',
                            value: expenseCount.toString(),
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Chart
                    const Text(
                      'Expense Trends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : CashFlowChart(
                              expenses: _expenses,
                              startDate: _startDate,
                              endDate: _endDate,
                            ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Category breakdown
                    _buildCategoryBreakdown(categoryData),
                    
                    const SizedBox(height: 24),
                    
                    // Expense list
                    _buildExpenseList(),
                    
                    // Load more button
                    if (_hasMoreData && !_isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: ElevatedButton(
                            onPressed: () => _loadExpenses(),
                            child: const Text('Load More'),
                          ),
                        ),
                      ),
                    
                    // Loading indicator at bottom
                    if (_isLoading && _expenses.isNotEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Category',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _selectedCategory,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'All Categories',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Categories'),
              ),
              ..._categories.map((category) => DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              )),
            ],
            onChanged: _onCategoryChanged,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryBreakdown(Map<String, dynamic> categoryData) {
    if (categoryData.isEmpty) {
      return const SizedBox();
    }
    
    // Calculate total for percentages
    final total = categoryData.values.fold<double>(
      0, (sum, value) => sum + (value as num).toDouble());
    
    // Sort categories by amount
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense by Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: sortedCategories.map((entry) {
              final category = entry.key;
              final amount = (entry.value as num).toDouble();
              final percentage = total > 0 ? (amount / total * 100) : 0;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###').format(amount)} (${percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(category),
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildExpenseList() {
    if (_isLoading && _expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No expenses found for the selected period',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _expenses.length,
          itemBuilder: (context, index) {
            final expense = _expenses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(expense.description),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.category),
                    if (expense.referenceNumber != null)
                      Text('Ref: ${expense.referenceNumber}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${NumberFormat('#,###').format(expense.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(expense.expenseDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(expense.category),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onTap: () {
                  // Navigate to expense detail screen
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => ExpenseDetailScreen(expenseId: expense.id!),
                  //   ),
                  // );
                },
                isThreeLine: expense.referenceNumber != null,
              ),
            );
          },
        ),
      ],
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'utilities':
        return Colors.blue;
      case 'rent':
        return Colors.purple;
      case 'supplies':
        return Colors.teal;
      case 'salary':
        return Colors.orange;
      case 'marketing':
        return Colors.green;
      case 'maintenance':
        return Colors.brown;
      case 'equipment':
        return Colors.indigo;
      case 'taxes':
        return Colors.red;
      case 'insurance':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'utilities':
        return Icons.electric_bolt;
      case 'rent':
        return Icons.home;
      case 'supplies':
        return Icons.shopping_cart;
      case 'salary':
        return Icons.people;
      case 'marketing':
        return Icons.campaign;
      case 'maintenance':
        return Icons.build;
      case 'equipment':
        return Icons.hardware;
      case 'taxes':
        return Icons.receipt;
      case 'insurance':
        return Icons.health_and_safety;
      default:
        return Icons.attach_money;
    }
  }
}