import 'package:flutter/material.dart' as material;
import '../../models/customer.dart';
import '../../models/transaction.dart' as app_transaction;
import '../../services/database_service.dart';
import 'customer_form.dart';

class CustomerDetailScreen extends material.StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  _CustomerDetailScreenState createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends material.State<CustomerDetailScreen> with material.SingleTickerProviderStateMixin {
  late material.TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  List<app_transaction.Transaction> _transactions = [];
  Customer? _refreshedCustomer;

  @override
  void initState() {
    super.initState();
    _tabController = material.TabController(length: 2, vsync: this);
    _refreshCustomerData();
    _loadTransactions();
  }

  Future<void> _refreshCustomerData() async {
    try {
      // Query untuk mendapatkan data customer
      final customerList = await _databaseService.query(
        'customers',
        where: 'id = ?',
        whereArgs: [widget.customer.id],
        limit: 1,
      );
      
      if (customerList.isNotEmpty) {
        setState(() {
          _refreshedCustomer = Customer.fromMap(customerList.first);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to load customer details: $e');
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Query untuk mendapatkan transaksi customer
      final transactionsList = await _databaseService.query(
        'transactions',
        where: 'customer_id = ?',
        whereArgs: [widget.customer.id],
        orderBy: 'transaction_date DESC',
      );
      
      setState(() {
        _transactions = transactionsList
            .map((map) => app_transaction.Transaction.fromMap(map))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load transactions: $e');
    }
  }

  void _showErrorDialog(String message) {
    material.showDialog(
      context: context,
      builder: (ctx) => material.AlertDialog(
        title: const material.Text('Error'),
        content: material.Text(message),
        actions: [
          material.TextButton(
            onPressed: () {
              material.Navigator.of(ctx).pop();
            },
            child: const material.Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final result = await material.showDialog<bool>(
      context: context,
      builder: (ctx) => material.AlertDialog(
        title: const material.Text('Confirm Delete'),
        content: material.Text('Are you sure you want to delete ${widget.customer.name}?'),
        actions: [
          material.TextButton(
            onPressed: () {
              material.Navigator.of(ctx).pop(false);
            },
            child: const material.Text('Cancel'),
          ),
          material.TextButton(
            onPressed: () {
              material.Navigator.of(ctx).pop(true);
            },
            child: const material.Text('Delete', style: material.TextStyle(color: material.Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteCustomer();
    }
  }

  Future<void> _deleteCustomer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete the customer
      await _databaseService.delete(
        'customers',
        'id = ?',
        [widget.customer.id],
      );
      
      setState(() {
        _isLoading = false;
      });
      // Return to previous screen and trigger refresh
      if (mounted) {
        material.Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to delete customer: $e');
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    final customer = _refreshedCustomer ?? widget.customer;

    return material.Scaffold(
      appBar: material.AppBar(
        title: material.Text(customer.name),
        actions: [
          material.IconButton(
            icon: const material.Icon(material.Icons.edit),
            onPressed: () async {
              final result = await material.Navigator.push(
                context,
                material.MaterialPageRoute(
                  builder: (context) => CustomerFormScreen(customer: customer),
                ),
              );
              if (result == true) {
                _refreshCustomerData();
              }
            },
          ),
          material.IconButton(
            icon: const material.Icon(material.Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
        bottom: material.TabBar(
          controller: _tabController,
          tabs: const [
            material.Tab(text: 'Details'),
            material.Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: _isLoading
          ? const material.Center(child: material.CircularProgressIndicator())
          : material.TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(customer),
                _buildTransactionsTab(),
              ],
            ),
    );
  }

  material.Widget _buildDetailsTab(Customer customer) {
    final List<material.Widget> children = [];
    
    // Basic Information Card
    children.add(_buildInfoCard(
      'Basic Information', 
      [
        _buildInfoRow('Customer ID', customer.code ?? 'Not Assigned'),
        _buildInfoRow('Name', customer.name),
        _buildInfoRow('Phone', customer.phone ?? 'Not Available'),
        _buildInfoRow('Email', customer.email ?? 'Not Available'),
        _buildInfoRow('Customer Type', customer.customerType ?? 'Regular'),
        _buildInfoRow('Join Date', customer.joinDate ?? 'Not Available'),
      ]
    ));
    
    children.add(const material.SizedBox(height: 16));
    
    // Financial Information Card
    final financialInfoRows = <material.Widget>[];
    
    final currentBalance = customer.currentBalance;
    financialInfoRows.add(_buildInfoRow(
      'Current Balance',
      currentBalance != null 
          ? 'Rp ${currentBalance.toStringAsFixed(2)}'
          : 'Rp 0.00',
    ));
    
    final creditLimit = customer.creditLimit;
    financialInfoRows.add(_buildInfoRow(
      'Credit Limit',
      creditLimit != null
          ? 'Rp ${creditLimit.toStringAsFixed(2)}'
          : 'Rp 0.00',
    ));
    
    final taxId = customer.taxId;
    if (taxId != null) {
      financialInfoRows.add(_buildInfoRow('Tax ID', taxId));
    }
    
    children.add(_buildInfoCard('Financial Information', financialInfoRows));
    
    children.add(const material.SizedBox(height: 16));
    
    // Address Information Card
    final address = customer.address;
    final city = customer.city;
    final postalCode = customer.postalCode;
    
    if (address != null || city != null || postalCode != null) {
      final addressRows = <material.Widget>[];
      
      if (address != null) {
        addressRows.add(_buildInfoRow('Address', address));
      }
      
      if (city != null) {
        addressRows.add(_buildInfoRow('City', city));
      }
      
      if (postalCode != null) {
        addressRows.add(_buildInfoRow('Postal Code', postalCode));
      }
      
      if (addressRows.isNotEmpty) {
        children.add(_buildInfoCard('Address Information', addressRows));
        children.add(const material.SizedBox(height: 16));
      }
    }
    
    // Notes Card
    final notes = customer.notes;
    if (notes != null && notes.isNotEmpty) {
      children.add(_buildInfoCard(
        'Notes',
        [
          material.Padding(
            padding: const material.EdgeInsets.only(bottom: 8.0),
            child: material.Text(notes),
          ),
        ]
      ));
    }
    
    return material.SingleChildScrollView(
      padding: const material.EdgeInsets.all(16.0),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  material.Widget _buildInfoCard(String title, List<material.Widget> children) {
    return material.Card(
      elevation: 4,
      child: material.Padding(
        padding: const material.EdgeInsets.all(16.0),
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            material.Text(
              title,
              style: const material.TextStyle(
                fontSize: 18,
                fontWeight: material.FontWeight.bold,
              ),
            ),
            const material.SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  material.Widget _buildInfoRow(String label, String value) {
    return material.Padding(
      padding: const material.EdgeInsets.only(bottom: 8.0),
      child: material.Row(
        crossAxisAlignment: material.CrossAxisAlignment.start,
        children: [
          material.SizedBox(
            width: 120,
            child: material.Text(
              label,
              style: const material.TextStyle(
                fontWeight: material.FontWeight.bold,
                color: material.Colors.grey,
              ),
            ),
          ),
          material.Expanded(
            child: material.Text(
              value,
              style: const material.TextStyle(
                fontWeight: material.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  material.Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return const material.Center(
        child: material.Text('No transactions found for this customer'),
      );
    }

    return material.ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return material.Card(
          margin: const material.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: material.ListTile(
            title: material.Text('Invoice: ${transaction.invoiceNumber}'),
            subtitle: material.Column(
              crossAxisAlignment: material.CrossAxisAlignment.start,
              mainAxisSize: material.MainAxisSize.min,
              children: [
                material.Text('Date: ${transaction.transactionDate}'),
                material.Text('Status: ${transaction.status}'),
              ],
            ),
            trailing: material.Text(
              'Rp ${transaction.grandTotal.toStringAsFixed(2)}',
              style: material.TextStyle(
                fontWeight: material.FontWeight.bold,
                color: transaction.paymentStatus == 'paid'
                    ? material.Colors.green
                    : material.Colors.red,
              ),
            ),
            onTap: () {
              // Navigate to transaction details (to be implemented)
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}