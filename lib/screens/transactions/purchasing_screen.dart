import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/loading_indicator.dart';
import 'transaction_detail_screen.dart';

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
  
  // We'll use this field to store all transactions directly to filtered lists
  // List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  List<Transaction> _salesTransactions = [];
  List<Transaction> _purchaseTransactions = [];
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
    // Store the context and mounted state before the async gap
    final currentContext = context;
    final isMounted = mounted;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseService();
      // Using rawQuery instead of missing getTransactions method
      final transactionsData = await db.rawQuery(
        'SELECT * FROM transactions WHERE transaction_date BETWEEN ? AND ?',
        [_startDate.toIso8601String(), _endDate.toIso8601String()]
      );
      
      final transactions = transactionsData.map((data) => Transaction.fromMap(data)).toList();

      // Check if widget is still mounted before updating state
      if (isMounted) {
        setState(() {
          // Store directly in filtered lists instead of using _allTransactions
          _salesTransactions = transactions.where((t) => t.type == 'sale').toList();
          _purchaseTransactions = transactions.where((t) => t.type == 'purchase').toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Check if widget is still mounted before showing SnackBar and updating state
      if (isMounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Transaction> transactions;
    
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
        final transDate = DateTime.parse(t.transactionDate ?? DateTime.now().toIso8601String());
        return transDate.isAfter(today.subtract(const Duration(seconds: 1))) && 
               transDate.isBefore(today.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == 'week') {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      transactions = transactions.where((t) {
        final transDate = DateTime.parse(t.transactionDate ?? DateTime.now().toIso8601String());
        return transDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
               transDate.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == 'month') {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      transactions = transactions.where((t) {
        final transDate = DateTime.parse(t.transactionDate ?? DateTime.now().toIso8601String());
        return transDate.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
               transDate.isBefore(now.add(const Duration(days: 1)));
      }).toList();
    } else if (_selectedFilter == 'custom') {
      transactions = transactions.where((t) {
        final transDate = DateTime.parse(t.transactionDate ?? DateTime.now().toIso8601String());
        return transDate.isAfter(_startDate.subtract(const Duration(seconds: 1))) && 
               transDate.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();
    }
    
    // Apply search query
    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((t) => 
        t.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (t.customerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        (t.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
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
            color: Colors.black.withAlpha(13), // approximately 0.05 opacity
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
                  : 'Search by invoice or notes',
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
      selectedColor: Theme.of(context).primaryColor.withAlpha(51), // approximately 0.2 opacity
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
        final transaction = _filteredTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isInvoice = transaction.type == 'sale';
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(
      DateTime.parse(transaction.transactionDate ?? DateTime.now().toIso8601String()),
    );
    
    // Using NumberFormat instead of missing currencyFormat
    final currencyFormatter = NumberFormat.currency(
      symbol: 'Rp ',
      decimalDigits: 0,
      locale: 'id_ID',
    );
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(
                transactionId: transaction.id ?? 0,
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
                      isInvoice ? transaction.invoiceNumber : transaction.invoiceNumber,
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
                              ? transaction.customerName ?? 'Walk-in Customer'
                              : transaction.notes ?? 'No supplier info',
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
                        currencyFormatter.format(transaction.grandTotal),
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