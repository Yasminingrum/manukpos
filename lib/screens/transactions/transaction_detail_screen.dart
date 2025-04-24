import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../models/transaction_item.dart';
import '../../models/payment.dart';
import '../../services/database_service.dart';
// import '../../widgets/loading_indicator.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Transaction? _transaction;
  List<TransactionItem> _items = [];
  List<Payment> _payments = [];
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadTransactionDetails();
  }

  Future<void> _loadTransactionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseService();
      
      // Fetch transaction using a custom query
      final transactions = await db.rawQuery(
        'SELECT t.*, c.name as customer_name, u.name as user_name, b.name as branch_name FROM transactions t LEFT JOIN customers c ON t.customer_id = c.id LEFT JOIN users u ON t.user_id = u.id LEFT JOIN branches b ON t.branch_id = b.id WHERE t.id = ?',
        [widget.transactionId]
      );
      
      if (transactions.isNotEmpty) {
        // Get customer, user and branch names
        final customer = transactions[0]['customer_id'] != null ? 
            await db.query('customers', where: 'id = ?', whereArgs: [transactions[0]['customer_id']]) : [];
        final user = await db.query('users', where: 'id = ?', whereArgs: [transactions[0]['user_id']]);
        final branch = await db.query('branches', where: 'id = ?', whereArgs: [transactions[0]['branch_id']]);
        
        final Map<String, dynamic> transactionData = Map.from(transactions[0]);
        transactionData['customerName'] = customer.isNotEmpty ? customer[0]['name'] : 'Walk-in Customer';
        transactionData['userName'] = user.isNotEmpty ? user[0]['name'] : 'Unknown';
        transactionData['branchName'] = branch.isNotEmpty ? branch[0]['name'] : 'Unknown';
        
        // Add extra fields needed by the UI
        transactionData['type'] = 'sale'; // Default to sale
        
        if (customer.isNotEmpty) {
          transactionData['customerPhone'] = customer[0]['phone'];
          transactionData['customerEmail'] = customer[0]['email'];
          transactionData['customerAddress'] = customer[0]['address'];
        }
        
        _transaction = Transaction.fromMap(transactionData);
      }
      
      // Fetch transaction items
      final items = await db.rawQuery(
        'SELECT ti.*, p.name as product_name FROM transaction_items ti JOIN products p ON ti.product_id = p.id WHERE ti.transaction_id = ?',
        [widget.transactionId]
      );
      
      _items = items.map((item) => TransactionItem.fromMap(item)).toList();
      
      // Fetch payments
      final payments = await db.rawQuery(
        'SELECT * FROM payments WHERE transaction_id = ? ORDER BY payment_date DESC',
        [widget.transactionId]
      );
      
      _payments = payments.map((payment) => Payment.fromMap(payment)).toList();

      if (mounted) { // Check if widget is still mounted before updating state
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { // Check if widget is still mounted before showing snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transaction details: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _printReceipt() async {
    // Store context in a local variable to use after async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Printing receipt...')),
    );
    // Implement receipt printing here
  }

  Future<void> _shareReceipt() async {
    // Store context in a local variable to use after async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Sharing receipt...')),
    );
  }

  Future<void> _addPayment() async {
    if (_transaction == null) return;
    
    final remainingAmount = _transaction!.grandTotal - _transaction!.amountPaid;
    if (remainingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This transaction is already fully paid')),
      );
      return;
    }

    // Store context in a local variable to use after async operation
    final currentContext = context;
    
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: currentContext,
      isScrollControlled: true,
      builder: (context) => _PaymentBottomSheet(
        remainingAmount: remainingAmount,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isProcessingPayment = true;
      });

      try {
        final db = DatabaseService();
        final payment = {
          'transaction_id': widget.transactionId,
          'payment_method': result['method'],
          'amount': result['amount'],
          'reference_number': result['reference'],
          'payment_date': DateTime.now().toIso8601String(),
          'status': 'completed',
          'notes': result['notes'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await db.insert('payments', payment);
        
        // Update transaction's payment status and amount_paid
        if (_transaction != null) {
          double newAmountPaid = _transaction!.amountPaid + result['amount'];
          String paymentStatus = 'unpaid';
          
          if (newAmountPaid >= _transaction!.grandTotal) {
            paymentStatus = 'paid';
          } else if (newAmountPaid > 0) {
            paymentStatus = 'partial';
          }
          
          // Use update method that's available in database service
          await db.execute(
            'UPDATE transactions SET amount_paid = ?, payment_status = ?, updated_at = ? WHERE id = ?',
            [newAmountPaid, paymentStatus, DateTime.now().toIso8601String(), widget.transactionId]
          );
        }
        
        await _loadTransactionDetails();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding payment: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingPayment = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReceipt,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transaction == null
              ? const Center(child: Text('Transaction not found'))
              : _buildTransactionDetails(),
      bottomNavigationBar: _isLoading || _transaction == null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildTransactionDetails() {
    final transaction = _transaction!;
    // We don't need isSales variable since it's not used
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildCustomerInfo(),
          const SizedBox(height: 16),
          _buildItemsList(),
          const SizedBox(height: 16),
          _buildSummary(),
          if (_payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPaymentHistory(),
          ],
          const SizedBox(height: 16),
          if (transaction.notes != null && transaction.notes!.isNotEmpty)
            _buildNotes(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final transaction = _transaction!;
    final formattedDate = transaction.transactionDate != null 
        ? DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(transaction.transactionDate!))
        : DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INVOICE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Date',
                    formattedDate,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Branch',
                    transaction.branchName ?? 'Unknown',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Created By',
                    transaction.userName ?? 'Unknown',
                  ),
                ),
                if (transaction.dueDate != null)
                  Expanded(
                    child: _buildInfoItem(
                      'Due Date',
                      DateFormat('dd MMM yyyy').format(
                        DateTime.parse(transaction.dueDate!),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final transaction = _transaction!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(transaction.grandTotal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PAYMENT STATUS',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(transaction.paymentStatus),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.paymentStatus.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (transaction.paymentStatus != 'paid')
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REMAINING',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(
                        transaction.grandTotal - transaction.amountPaid,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    final transaction = _transaction!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CUSTOMER INFORMATION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              transaction.customerName ?? 'Walk-in Customer',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Only display related customer details if they exist in the database
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ITEMS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Product',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Qty',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Price',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Subtotal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName ?? 'Unknown Product',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              item.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.quantity.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(item.unitPrice),
                          ),
                          if (item.discountAmount > 0)
                            Text(
                              '-${currencyFormat.format(item.discountAmount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        currencyFormat.format(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final transaction = _transaction!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SUMMARY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Subtotal', transaction.subtotal),
            if (transaction.discountAmount > 0)
              _buildSummaryRow(
                'Discount',
                -transaction.discountAmount,
                color: Colors.red,
              ),
            if (transaction.taxAmount > 0)
              _buildSummaryRow('Tax', transaction.taxAmount),
            if (transaction.feeAmount > 0)
              _buildSummaryRow('Fee', transaction.feeAmount),
            if (transaction.shippingCost > 0)
              _buildSummaryRow('Shipping', transaction.shippingCost),
            const Divider(),
            _buildSummaryRow(
              'Grand Total',
              transaction.grandTotal,
              isBold: true,
            ),
            if (transaction.amountPaid > 0) ...[
              _buildSummaryRow(
                'Paid',
                transaction.amountPaid,
                color: Colors.green,
              ),
              _buildSummaryRow(
                'Remaining',
                transaction.grandTotal - transaction.amountPaid,
                color: transaction.paymentStatus != 'paid' ? Colors.red : null,
                isBold: transaction.paymentStatus != 'paid',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PAYMENT HISTORY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _payments.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final payment = _payments[index];
                final formattedDate = payment.paymentDate != null 
                    ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(payment.paymentDate!))
                    : DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
                
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.paymentMethod.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty)
                            Text(
                              'Ref: ${payment.referenceNumber!}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (payment.notes != null && payment.notes!.isNotEmpty)
                            Text(
                              payment.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        currencyFormat.format(payment.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NOTES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _transaction!.notes!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final transaction = _transaction!;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),  // Use withAlpha instead of withOpacity
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (transaction.paymentStatus != 'paid' && !_isProcessingPayment)
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Add Payment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _addPayment,
              ),
            ),
          if (_isProcessingPayment)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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

class _PaymentBottomSheet extends StatefulWidget {
  final double remainingAmount;

  const _PaymentBottomSheet({
    required this.remainingAmount,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'cash';
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.remainingAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 16,
        right: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              value: _paymentMethod,
              items: const [
                DropdownMenuItem(
                  value: 'cash',
                  child: Text('Cash'),
                ),
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text('Bank Transfer'),
                ),
                DropdownMenuItem(
                  value: 'credit_card',
                  child: Text('Credit Card'),
                ),
                DropdownMenuItem(
                  value: 'e_wallet',
                  child: Text('E-Wallet'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount > widget.remainingAmount) {
                  return 'Amount cannot exceed the remaining balance';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_paymentMethod != 'cash')
              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: _getReferenceLabel(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_paymentMethod != 'cash' && (value == null || value.isEmpty)) {
                    return 'Please enter a reference number';
                  }
                  return null;
                },
              ),
            if (_paymentMethod != 'cash') const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      {
                        'method': _paymentMethod,
                        'amount': double.parse(_amountController.text),
                        'reference': _referenceController.text,
                        'notes': _notesController.text,
                      },
                    );
                  }
                },
                child: const Text(
                  'Save Payment',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getReferenceLabel() {
    switch (_paymentMethod) {
      case 'bank_transfer':
        return 'Transfer Reference';
      case 'credit_card':
        return 'Approval Code';
      case 'e_wallet':
        return 'Transaction ID';
      default:
        return 'Reference Number';
    }
  }
}