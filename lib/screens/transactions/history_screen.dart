import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_indicator.dart';
import 'transaction_detail_screen.dart';

// Wrapper class for Transaction with additional properties
class TransactionWrapper {
  final Transaction transaction;
  String? customerName;
  String? supplierName;
  
  TransactionWrapper(this.transaction, {this.customerName, this.supplierName});
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<TransactionWrapper> _allTransactions = [];
  List<TransactionWrapper> _filteredTransactions = [];
  List<TransactionWrapper> _salesTransactions = [];
  List<TransactionWrapper> _purchaseTransactions = [];
  bool _isLoading = true;
  
  String _selectedFilter = 'all'; // all, today, week, month, custom
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _applyFilters();
      });
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseService();
      
      // Query transactions from database using custom where conditions for date filtering
      final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate.add(const Duration(days: 1)));
      
      final transactionsData = await db.query(
        'transactions',
        where: 'transaction_date BETWEEN ? AND ?',
        whereArgs: [startDateStr, endDateStr],
        orderBy: 'transaction_date DESC',
      );
      
      // Convert to TransactionWrapper objects and fetch related entities
      List<TransactionWrapper> transactions = [];
      for (var data in transactionsData) {
        final transaction = Transaction.fromMap(data);
        String? customerName;
        String? supplierName;
        
        // Get customer name if needed
        if (data['customer_id'] != null) {
          final customerData = await db.query(
            'customers',
            where: 'id = ?',
            whereArgs: [data['customer_id']],
            limit: 1,
          );
          if (customerData.isNotEmpty) {
            customerName = customerData.first['name'] as String;
          }
        }
        
        // Get supplier name if needed
        if (data['supplier_id'] != null) {
          final supplierData = await db.query(
            'suppliers',
            where: 'id = ?',
            whereArgs: [data['supplier_id']],
            limit: 1,
          );
          if (supplierData.isNotEmpty) {
            supplierName = supplierData.first['name'] as String;
          }
        }
        
        transactions.add(TransactionWrapper(
          transaction,
          customerName: customerName,
          supplierName: supplierName,
        ));
      }

      setState(() {
        _allTransactions = transactions;
        _salesTransactions = transactions.where((t) => t.transaction.type == 'sale').toList();
        _purchaseTransactions = transactions.where((t) => t.transaction.type == 'purchase').toList();
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<TransactionWrapper> transactions;
    
    // Get transactions based on tab
    if (_tabController.index == 0) {
      transactions = List.from(_salesTransactions);
    } else {
      transactions = List.from(_purchaseTransactions);
    }
    
    // Apply date filter
    if (_selectedFilter == 'today') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      transactions = transactions.where((t) {
        final transDate = DateTime.parse(t.transaction.transactionDate);
        return transDate.isAfter(today.subtract(const Duration(seconds: 1))) && 
               transDate.isBefore(today.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == 'week') {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      transactions = transactions.where((t) {
        final transDate = DateTime.parse(t.transaction.transactionDate);
        return transDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
               transDate.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == 'month') {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      transactions = transactions.where((t) {
        final transDate = DateTime.parse(t.transaction.transactionDate);
        return transDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
               transDate.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == 'custom') {
      transactions = transactions.where((t) {
        final transDate = DateTime.parse(t.transaction.transactionDate);
        return transDate.isAfter(_startDate.subtract(const Duration(seconds: 1))) && 
               transDate.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();
    }
    
    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      transactions = transactions.where((t) {
        return t.transaction.invoiceNumber.toLowerCase().contains(lowerQuery) ||
            (t.customerName?.toLowerCase().contains(lowerQuery) ?? false) ||
            (t.supplierName?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
    
    setState(() {
      _filteredTransactions = transactions;
    });
  }

  void _updateDateRange(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilters();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 'custom';
        _applyFilters();
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Purchases'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const LoadingIndicator()
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionList(),
                      _buildTransactionList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _tabController.index == 0
                  ? 'Search by invoice or customer'
                  : 'Search by invoice or supplier',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Today', 'today'),
                const SizedBox(width: 8),
                _buildFilterChip('This Week', 'week'),
                const SizedBox(width: 8),
                _buildFilterChip('This Month', 'month'),
                const SizedBox(width: 8),
                _buildFilterChip(
                  _selectedFilter == 'custom'
                      ? '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}'
                      : 'Custom Range',
                  'custom',
                  onSelected: (_) => _selectDateRange(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {Function(bool)? onSelected}) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: onSelected ?? (selected) {
        if (selected) {
          _updateDateRange(value);
        }
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildTransactionList() {
    if (_filteredTransactions.isEmpty) {
      return const Center(
        child: Text('No transactions found'),
      );
    }

    return ListView.builder(
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transactionWrapper = _filteredTransactions[index];
        return _buildTransactionItem(transactionWrapper);
      },
    );
  }

  Widget _buildTransactionItem(TransactionWrapper wrapper) {
    final transaction = wrapper.transaction;
    final customerName = wrapper.customerName;
    final supplierName = wrapper.supplierName;
    
    // Check if it's a sales transaction
    final isInvoice = transaction.type == 'sale';
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(
      DateTime.parse(transaction.transactionDate),
    );
    
    // Create a currency formatter
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(
                transactionId: transaction.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      transaction.invoiceNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isInvoice
                              ? (customerName ?? 'Walk-in Customer')
                              : (supplierName ?? 'Unknown Supplier'),
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(transaction.grandTotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(transaction.paymentStatus),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.paymentStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}