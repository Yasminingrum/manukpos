// screens/transactions/purchasing_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/supplier.dart';
import '../../models/product.dart';
// import '../../models/inventory_movement.dart';
import '../../services/database_service.dart';
import '../../services/inventory_service.dart';
import '../../services/api_service.dart'; // Import the ApiService class
// import '../../utils/formatters.dart';
import '../../utils/validation_utils.dart';
import '../../widgets/custom_app_bar.dart';
// import '../../widgets/custom_button.dart';
// import '../../widgets/confirmation_dialog.dart';
import '../../widgets/loading_overlay.dart';

class PurchasingScreen extends StatefulWidget {
  const PurchasingScreen({super.key});

  @override
  State<PurchasingScreen> createState() => _PurchasingScreenState();
}

class _PurchasingScreenState extends State<PurchasingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final DatabaseService _databaseService = DatabaseService();
  final InventoryService _inventoryService = InventoryService(
    databaseService: DatabaseService(),
    apiService: ApiService(baseUrl: 'https://documenter.getpostman.com/view/37267696/2sB2ca8L6X'),
  );
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  bool _isLoading = false;
  List<Supplier> _suppliers = [];
  List<Product> _products = [];
  Supplier? _selectedSupplier;
  
  // Purchasing form data
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  
  // Item cart
  List<PurchaseItem> _items = [];
  double _totalAmount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _generateReferenceNumber();
  }
  
  @override
  void dispose() {
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load suppliers
      final supplierList = await _databaseService.query('suppliers');
      _suppliers = supplierList.map((map) => Supplier.fromMap(map)).toList();
      
      // Load products
      final productList = await _databaseService.query('products', orderBy: 'name ASC');
      _products = productList.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      _showSnackBar('Error loading data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _generateReferenceNumber() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final randomStr = now.millisecondsSinceEpoch.toString().substring(8);
    _referenceController.text = 'PO-$dateStr-$randomStr';
  }
  
  void _updateTotalAmount() {
    double total = 0;
    for (var item in _items) {
      total += item.quantity * item.unitPrice;
    }
    setState(() => _totalAmount = total);
  }
  
  
  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    
    _updateTotalAmount();
  }
  
  void _editItem(int index) {
    _showAddItemDialog(_items[index], index);
  }
  
  void _showAddItemDialog([PurchaseItem? existingItem, int? editIndex]) {
    showDialog(
      context: context,
      builder: (context) {
        return AddPurchaseItemDialog(
          products: _products,
          onItemAdded: (item) {
            if (editIndex != null) {
              // Update existing item
              setState(() {
                _items[editIndex] = item;
              });
            } else {
              // Add new item
              setState(() {
                _items.add(item);
              });
            }
            _updateTotalAmount();
          },
          existingItem: existingItem,
        );
      },
    );
  }
  
  Future<void> _savePurchase() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    if (_items.isEmpty) {
      _showSnackBar('Tambahkan setidaknya satu item!');
      return;
    }
    
    if (_selectedSupplier == null) {
      _showSnackBar('Pilih supplier terlebih dahulu!');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Generate transaction data
      final int branchId = 1; // Replace with actual branch ID from your app state
      final int userId = 1; // Replace with actual user ID from your app state
      
      // Insert purchase header
      final purchaseHeader = {
        'reference_number': _referenceController.text,
        'supplier_id': _selectedSupplier!.id,
        'branch_id': branchId,
        'user_id': userId,
        'purchase_date': _purchaseDate.toIso8601String(),
        'total_amount': _totalAmount,
        'notes': _notesController.text,
        'status': 'completed',
        'payment_status': 'paid', // Or 'unpaid' based on your business flow
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final purchaseId = await _databaseService.insert('purchases', purchaseHeader);
      
      // Insert purchase items and update inventory
      for (final item in _items) {
        // Insert purchase item
        final purchaseItem = {
          'purchase_id': purchaseId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.quantity * item.unitPrice,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await _databaseService.insert('purchase_items', purchaseItem);
        
        // Update inventory
        await _inventoryService.addInventoryTransaction(
          item.product.id,
          branchId,
          'in', // Transaction type: 'in' for purchases
          item.quantity,
          referenceType: 'purchase',
          referenceId: purchaseId,
          unitPrice: item.unitPrice,
          notes: 'Stock update from purchase',
          userId: userId,
        );
      }
      
      // Show success and clear form
      _showSnackBar('Pembelian berhasil disimpan!');
      
      // Reset form
      setState(() {
        _items = [];
        _totalAmount = 0;
        _notesController.clear();
        _generateReferenceNumber();
        _selectedSupplier = null;
        _purchaseDate = DateTime.now();
      });
      
    } catch (e) {
      _showSnackBar('Error saving purchase: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Pembelian Barang',
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/transactions/history', arguments: 'purchase');
            },
            tooltip: 'Riwayat Pembelian',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Purchase header section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Pembelian',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Reference number
                        TextFormField(
                          controller: _referenceController,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Referensi',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => ValidationUtils.validateRequired(
                            value,
                            'Nomor referensi wajib diisi',
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Supplier selection
                        DropdownButtonFormField<Supplier>(
                          value: _selectedSupplier,
                          decoration: const InputDecoration(
                            labelText: 'Supplier',
                            border: OutlineInputBorder(),
                          ),
                          items: _suppliers.map((supplier) {
                            return DropdownMenuItem<Supplier>(
                              value: supplier,
                              child: Text(supplier.name),
                            );
                          }).toList(),
                          onChanged: (Supplier? value) {
                            setState(() {
                              _selectedSupplier = value;
                            });
                          },
                          validator: (value) => value == null ? 'Pilih supplier' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Purchase date
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _purchaseDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                            );
                            
                            if (date != null) {
                              setState(() {
                                _purchaseDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Pembelian',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd MMMM yyyy').format(_purchaseDate)),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Purchase items section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daftar Item',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Item'),
                              onPressed: () => _showAddItemDialog(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Items list
                        if (_items.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Belum ada item. Tambahkan item untuk mulai.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item.product.name),
                                subtitle: Text(
                                  '${item.quantity} x ${currencyFormatter.format(item.unitPrice)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currencyFormatter.format(item.quantity * item.unitPrice),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editItem(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _removeItem(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        
                        const Divider(thickness: 1),
                        
                        // Total
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                currencyFormatter.format(_totalAmount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cancel),
                        label: const Text('Batal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi Batal'),
                              content: const Text('Apakah Anda yakin ingin membatalkan pembelian ini? Semua data yang telah diinput akan hilang.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Tidak'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(context); // Close screen
                                  },
                                  child: const Text('Ya, Batalkan'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        onPressed: _savePurchase,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class for purchase items
class PurchaseItem {
  final Product product;
  final double quantity;
  final double unitPrice;
  
  PurchaseItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });
}

// Dialog for adding purchase items
class AddPurchaseItemDialog extends StatefulWidget {
  final List<Product> products;
  final Function(PurchaseItem) onItemAdded;
  final PurchaseItem? existingItem;
  
  const AddPurchaseItemDialog({
    super.key,
    required this.products,
    required this.onItemAdded,
    this.existingItem,
  });
  
  @override
  State<AddPurchaseItemDialog> createState() => _AddPurchaseItemDialogState();
}

class _AddPurchaseItemDialogState extends State<AddPurchaseItemDialog> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with existing item if editing
    if (widget.existingItem != null) {
      _selectedProduct = widget.existingItem!.product;
      _quantityController.text = widget.existingItem!.quantity.toString();
      _priceController.text = widget.existingItem!.unitPrice.toString();
    }
  }
  
  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingItem != null ? 'Edit Item' : 'Tambah Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product selection
              DropdownButtonFormField<Product>(
                value: _selectedProduct,
                decoration: const InputDecoration(
                  labelText: 'Produk',
                  border: OutlineInputBorder(),
                ),
                items: widget.products.map((product) {
                  return DropdownMenuItem<Product>(
                    value: product,
                    child: Text(product.name),
                  );
                }).toList(),
                onChanged: (Product? value) {
                  setState(() {
                    _selectedProduct = value;
                    if (value != null && _priceController.text.isEmpty) {
                      _priceController.text = value.buyingPrice.toString();
                    }
                  });
                },
                validator: (value) => value == null ? 'Pilih produk' : null,
              ),
              const SizedBox(height: 16),
              
              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah wajib diisi';
                  }
                  final double? qty = double.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Jumlah harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Unit price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga Satuan',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga satuan wajib diisi';
                  }
                  final double? price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Harga harus lebih dari 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              final item = PurchaseItem(
                product: _selectedProduct!,
                quantity: double.parse(_quantityController.text),
                unitPrice: double.parse(_priceController.text),
              );
              
              widget.onItemAdded(item);
              Navigator.pop(context);
            }
          },
          child: Text(widget.existingItem != null ? 'Update' : 'Tambah'),
        ),
      ],
    );
  }
}