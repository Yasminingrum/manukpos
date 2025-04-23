// lib/screens/transactions/pos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// Using mobile_scanner instead of flutter_barcode_scanner
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/pos_cart_item.dart';
import '../../widgets/customer_selector.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final List<Map<String, dynamic>> _cartItems = [];
  Customer? _selectedCustomer;
  String _paymentMethod = 'cash';
  double _receivedAmount = 0;
  
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  String _searchQuery = '';
  int _currentView = 0; // 0: Products, 1: Cart
  
  double get _subtotal => _cartItems.fold(0, (sum, item) => 
      sum + (item['quantity'] as double) * (item['price'] as double));
  
  double get _tax => 0;
  double get _discount => 0;
  double get _total => _subtotal + _tax - _discount;
  double get _change => _receivedAmount > _total ? _receivedAmount - _total : 0;
  bool get _canCheckout => _cartItems.isNotEmpty;
  bool get _canProcessPayment => _receivedAmount >= _total || _paymentMethod != 'cash';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final branchId = authService.currentBranch?.id;
      
      if (branchId == null) throw Exception('Branch ID is required');
      
      final query = '''
        SELECT p.*, c.name as category_name, i.quantity as current_stock
        FROM ${AppConstants.tableProducts} p
        LEFT JOIN ${AppConstants.tableCategories} c ON p.category_id = c.id
        LEFT JOIN ${AppConstants.tableInventory} i ON p.id = i.product_id AND i.branch_id = $branchId
        WHERE p.is_active = 1
        ORDER BY p.name
      ''';
      
      final results = await databaseService.rawQuery(query);
      final products = results.map((map) => Product.fromMap(map)).toList();
      
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading products: $e');
      }
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProducts = query.isEmpty 
          ? _products 
          : _products.where((product) {
              final name = product.name.toLowerCase();
              final sku = product.sku.toLowerCase();
              final barcode = product.barcode?.toLowerCase() ?? '';
              final searchLower = _searchQuery.toLowerCase();
              return name.contains(searchLower) || 
                     sku.contains(searchLower) || 
                     barcode.contains(searchLower);
            }).toList();
    });
  }

  Future<void> _scanBarcode() async {
    try {
      // Using mobile_scanner instead of flutter_barcode_scanner
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Scan Barcode'),
            ),
            body: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? barcode = barcodes.first.rawValue;
                  if (barcode != null) {
                    Navigator.of(context).pop();
                    _processBarcodeResult(barcode);
                  }
                }
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning barcode: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Terjadi kesalahan saat membaca barcode'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _processBarcodeResult(String barcode) {
    try {
      final product = _products.firstWhere(
        (p) => p.barcode == barcode,
        orElse: () => throw Exception('Product not found'),
      );
      _addToCart(product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Produk dengan barcode tersebut tidak ditemukan'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _addToCart(Product product) {
    final index = _cartItems.indexWhere((item) => item['product_id'] == product.id);
    
    setState(() {
      if (index >= 0) {
        _cartItems[index]['quantity'] = (_cartItems[index]['quantity'] as double) + 1;
      } else {
        _cartItems.add({
          'product_id': product.id,
          'name': product.name,
          'price': product.discountPrice ?? product.sellingPrice,
          'original_price': product.sellingPrice,
          'quantity': 1.0,
          'allow_fractions': product.allowFractions,
          'is_service': product.isService,
          'product': product,
        });
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang'),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updateCartItemQuantity(int index, double quantity) {
    if (quantity <= 0) {
      _removeCartItem(index);
    } else {
      setState(() {
        _cartItems[index]['quantity'] = quantity;
      });
    }
  }

  void _removeCartItem(int index) {
    setState(() => _cartItems.removeAt(index));
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan Keranjang'),
        content: const Text('Apakah anda yakin ingin mengosongkan keranjang belanja?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _cartItems.clear();
                _selectedCustomer = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Ya, Kosongkan'),
          ),
        ],
      ),
    );
  }

  // Method to show checkout dialog
  void _showCheckoutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return _buildCheckoutDialog(setModalState);
          },
        );
      },
    );
  }

  Widget _buildCheckoutDialog(StateSetter setModalState) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Checkout', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Order Summary
          Card(
            elevation: 0,
            color: AppTheme.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text(currencyFormat.format(_subtotal)),
                    ],
                  ),
                  if (_tax > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pajak'),
                        Text(currencyFormat.format(_tax)),
                      ],
                    ),
                  ],
                  if (_discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Diskon'),
                        Text('-${currencyFormat.format(_discount)}'),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currencyFormat.format(_total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Customer Selection
          ListTile(
            title: const Text('Pelanggan'),
            subtitle: Text(_selectedCustomer?.name ?? 'Umum'),
            leading: const Icon(Icons.person),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            onTap: () async {
              final customer = await showModalBottomSheet<Customer>(
                context: context,
                isScrollControlled: true,
                builder: (context) => const CustomerSelector(),
              );
              
              if (customer != null) {
                setModalState(() => _selectedCustomer = customer);
                setState(() => _selectedCustomer = customer);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Payment Method Selection
          const Text(
            'Metode Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildPaymentMethodChip('cash', 'Tunai', Icons.money, setModalState),
              _buildPaymentMethodChip('card', 'Kartu', Icons.credit_card, setModalState),
              _buildPaymentMethodChip('e_wallet', 'E-Wallet', Icons.account_balance_wallet, setModalState),
            ],
          ),
          
          if (_paymentMethod == 'cash') ...[
            const SizedBox(height: 16),
            const Text(
              'Jumlah Diterima',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final amount = double.tryParse(value.replaceAll('.', '')) ?? 0;
                      setModalState(() => _receivedAmount = amount);
                      setState(() => _receivedAmount = amount);
                    },
                    controller: TextEditingController(
                      text: _receivedAmount.round().toString(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setModalState(() => _receivedAmount = _total);
                    setState(() => _receivedAmount = _total);
                  },
                  child: const Text('Uang Pas'),
                ),
              ],
            ),
            if (_receivedAmount >= _total) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian:'),
                  Text(
                    currencyFormat.format(_change),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
          
          const SizedBox(height: 24),
          
          // Process Payment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canProcessPayment ? () {
                Navigator.pop(context);
                _processPayment();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessingPayment
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Proses Pembayaran'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChip(
    String value,
    String label,
    IconData icon,
    StateSetter setModalState,
  ) {
    final isSelected = _paymentMethod == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _paymentMethod = value);
          setState(() => _paymentMethod = value);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_cartItems.isEmpty) return;
    
    setState(() => _isProcessingPayment = true);
    
    try {
      final database = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      final branchId = authService.currentBranch?.id;
      
      if (userId == null || branchId == null) {
        throw Exception('User ID and Branch ID are required');
      }
      
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy/MM/dd');
      final dateString = dateFormat.format(now);
      
      final latestInvoiceQuery = '''
        SELECT invoice_number 
        FROM ${AppConstants.tableTransactions}
        WHERE invoice_number LIKE 'INV/$dateString/%'
        ORDER BY id DESC
        LIMIT 1
      ''';
      
      final latestInvoices = await database.rawQuery(latestInvoiceQuery);
      int counter = latestInvoices.isNotEmpty 
          ? int.parse((latestInvoices.first['invoice_number'] as String).split('/')[3]) + 1
          : 1;
      
      final invoiceNumber = 'INV/$dateString/${counter.toString().padLeft(4, '0')}';
      
      await database.transaction((txn) async {
        final transactionId = await txn.insert(
          AppConstants.tableTransactions,
          {
            'invoice_number': invoiceNumber,
            'invoice_date': now.toIso8601String(),
            'customer_id': _selectedCustomer?.id,
            'user_id': userId,
            'branch_id': branchId,
            'transaction_date': now.toIso8601String(),
            'subtotal': _subtotal,
            'discount_amount': _discount,
            'tax_amount': _tax,
            'grand_total': _total,
            'amount_paid': _paymentMethod == 'cash' ? _receivedAmount : _total,
            'amount_returned': _paymentMethod == 'cash' ? _change : 0,
            'payment_status': 'paid',
            'status': 'completed',
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'sync_status': 'pending',
          },
        );
        
        for (final item in _cartItems) {
          final product = item['product'] as Product;
          final quantity = item['quantity'] as double;
          final price = item['price'] as double;
          
          await txn.insert(
            AppConstants.tableTransactionItems,
            {
              'transaction_id': transactionId,
              'product_id': product.id,
              'quantity': quantity,
              'unit_price': price,
              'original_price': product.sellingPrice,
              'subtotal': quantity * price,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
              'sync_status': 'pending',
            },
          );
          
          if (!product.isService) {
            final inventoryQuery = '''
              SELECT id, quantity FROM ${AppConstants.tableInventory}
              WHERE product_id = ${product.id} AND branch_id = $branchId
            ''';
            
            final inventoryResults = await txn.rawQuery(inventoryQuery);
            
            if (inventoryResults.isNotEmpty) {
              final inventoryId = inventoryResults.first['id'] as int;
              final currentQuantity = (inventoryResults.first['quantity'] as num).toDouble();
              
              await txn.update(
                AppConstants.tableInventory,
                {
                  'quantity': currentQuantity - quantity,
                  'last_stock_update': now.toIso8601String(),
                  'updated_at': now.toIso8601String(),
                },
                where: 'id = ?',
                whereArgs: [inventoryId],
              );
            }
            
            await txn.insert(
              'inventory_transactions',
              {
                'transaction_date': now.toIso8601String(),
                'reference_id': transactionId,
                'reference_type': 'sale',
                'product_id': product.id,
                'branch_id': branchId,
                'transaction_type': 'out',
                'quantity': quantity,
                'unit_price': price,
                'user_id': userId,
                'created_at': now.toIso8601String(),
              },
            );
          }
        }
        
        await txn.insert(
          AppConstants.tablePayments,
          {
            'transaction_id': transactionId,
            'payment_method': _paymentMethod,
            'amount': _total,
            'payment_date': now.toIso8601String(),
            'status': 'completed',
            'user_id': userId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'sync_status': 'pending',
          },
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi berhasil disimpan dengan nomor $invoiceNumber'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      
      setState(() {
        _cartItems.clear();
        _selectedCustomer = null;
        _paymentMethod = 'cash';
        _receivedAmount = 0;
        _isProcessingPayment = false;
      });
      
      _loadProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error processing payment: $e');
      }
      setState(() => _isProcessingPayment = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildCartView() {
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Keranjang Kosong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan produk ke keranjang',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.backgroundColor,
          child: Row(
            children: [
              Text(
                'Keranjang (${_cartItems.length} Item)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearCart,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Kosongkan',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              final product = item['product'] as Product;
              final quantity = item['quantity'] as double;
              final price = item['price'] as double;
              
              return PosCartItem(
                name: product.name,
                subtotal: quantity * price,
                allowFractions: product.allowFractions,
                product: product,
                quantity: quantity,
                price: price,
                onQuantityChanged: (value) => _updateCartItemQuantity(index, value),
                onRemove: () => _removeCartItem(index),
              );
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(128, 128, 128, 0.2), // Fixed deprecated withOpacity
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text(currencyFormat.format(_subtotal)),
                ],
              ),
              if (_tax > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pajak'),
                    Text(currencyFormat.format(_tax)),
                  ],
                ),
              ],
              if (_discount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Diskon'),
                    Text('-${currencyFormat.format(_discount)}'),
                  ],
                ),
              ],
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    currencyFormat.format(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canCheckout ? _showCheckoutDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Checkout'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.barcode_reader),
                onPressed: _scanBarcode,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _filterProducts,
          ),
        ),
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return Card(
                elevation: 2,
                child: InkWell(
                  onTap: () => _addToCart(product),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.sku,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          currencyFormat.format(product.sellingPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.currentStock != null && !product.isService)
                          Text(
                            'Stok: ${product.currentStock}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => setState(() => _currentView = 1),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentView == 0 ? _buildProductView() : _buildCartView(),
      floatingActionButton: _currentView == 1
          ? FloatingActionButton(
              onPressed: () => setState(() => _currentView = 0),
              child: const Icon(Icons.arrow_back),
            )
          : null,
    );
  }
}
