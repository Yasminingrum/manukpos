// stock_opname.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:logger/logger.dart';
import '../../models/product.dart';
import '../../models/stock_opname.dart';
import '../../services/database_service.dart';
import '../../widgets/loading_overlay.dart';

// Logger untuk pengganti print
final logger = Logger();

class StockOpnameScreen extends StatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  State<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends State<StockOpnameScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  
  // For creating new stock opname
  StockOpname? _currentOpname;
  List<StockOpnameItem> _opnameItems = [];
  
  // UI states
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _hasChanges = false;
  String _searchQuery = '';
  List<Product> _filteredProducts = [];
  
  // Branch selection
  int? _selectedBranchId;
  List<Map<String, dynamic>> _branches = [];
  
  // Current tab index
  int _currentTabIndex = 0;
  
  // Ongoing opnames
  List<StockOpname> _ongoingOpnames = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Load branches - using query instead of getAllBranches
      final branches = await _databaseService.query('branches');
      
      // Load ongoing opnames - using query for stock opnames with status 'draft'
      final opnamesList = await _databaseService.query(
        'stock_opname',
        where: "status = ?",
        whereArgs: ['draft'],
      );
      
      final List<StockOpname> opnames = opnamesList.map((map) => StockOpname(
        id: map['id'],
        branchId: map['branch_id'],
        userId: map['user_id'],
        referenceNumber: map['reference_number'],
        opnameDate: map['opname_date'],
        status: map['status'],
        notes: map['notes'] ?? '',
      )).toList();

      if (mounted) {
        setState(() {
          _branches = branches;
          _selectedBranchId = branches.isNotEmpty ? branches[0]['id'] as int : null;
          _ongoingOpnames = opnames;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _showErrorSnackBar('Error initializing: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _createNewOpname() async {
    if (_selectedBranchId == null) {
      _showErrorSnackBar('Please select a branch first');
      return;
    }

    final String? reference = await _showReferenceDialog();
    if (reference == null) {
      return; // User cancelled
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = 1;
      final now = DateTime.now().toIso8601String();
      
      final Map<String, dynamic> opnameData = {
        'branch_id': _selectedBranchId,
        'user_id': userId,
        'reference_number': reference,
        'opname_date': now,
        'status': 'draft',
        'notes': '',
        'created_at': now,
        'updated_at': now,
      };

      final opnameId = await _databaseService.insert('stock_opname', opnameData);
      
      // Ubah pendekatan untuk mendapatkan produk:
      // 1. Dapatkan semua produk aktif
      final products = await _databaseService.query(
        'products',
        where: 'is_active = ?',
        whereArgs: [1],
      );
      
      if (products.isEmpty) {
        if (mounted) {
          _showErrorSnackBar('Tidak ada produk aktif di database');
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      // 2. Untuk setiap produk, cek inventori di cabang ini
      final List<StockOpnameItem> opnameItems = [];
      final List<Product> productsList = [];
      
      for (final product in products) {
        final productId = product['id'] as int;
        
        // Cari inventori untuk produk ini di cabang yg dipilih
        final inventoryItems = await _databaseService.query(
          'inventory',
          where: 'product_id = ? AND branch_id = ?',
          whereArgs: [productId, _selectedBranchId],
          limit: 1,
        );
        
        // Default quantity ke 0 jika tidak ada inventori
        final double quantity = inventoryItems.isNotEmpty 
            ? (inventoryItems.first['quantity'] as num?)?.toDouble() ?? 0.0
            : 0.0;
        
        // Buat stock opname item
        opnameItems.add(StockOpnameItem(
          id: 0,
          stockOpnameId: opnameId,
          productId: productId,
          productName: product['name'] as String,
          productSku: product['sku'] as String,
          systemStock: quantity,
          physicalStock: quantity,
          difference: 0,
          notes: '',
        ));
        
        // Tambahkan ke daftar produk
        productsList.add(Product(
          id: productId,
          sku: product['sku'] as String,
          barcode: product['barcode'] as String?,
          name: product['name'] as String,
          categoryId: (product['category_id'] as num?)?.toInt() ?? 0,
          category: '',
          buyingPrice: (product['buying_price'] as num?)?.toDouble() ?? 0.0,
          sellingPrice: (product['selling_price'] as num?)?.toDouble() ?? 0.0,
          createdAt: product['created_at'] as String? ?? now,
          updatedAt: product['updated_at'] as String? ?? now,
        ));
      }
      
      if (mounted) {
        setState(() {
          _currentOpname = StockOpname(
            id: opnameId,
            branchId: _selectedBranchId!,
            userId: userId,
            referenceNumber: reference,
            opnameDate: now,
            status: 'draft',
            notes: '',
          );
          _opnameItems = opnameItems;
          _filteredProducts = productsList;
          _isLoading = false;
          _currentTabIndex = 1;
        });
      
        // Beri tahu pengguna berapa produk yang ditemukan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil memuat ${productsList.length} produk'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error creating stock opname: $e');
      }
    }
  }

  Future<String?> _showReferenceDialog() async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Opname Reference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a reference number for this stock opname:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Reference Number',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              } else {
                // Show error about empty field
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reference number'),
                  ),
                );
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadExistingOpname(int opnameId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load opname details - using query instead of getStockOpnameById
      final opnamesList = await _databaseService.query(
        'stock_opname',
        where: 'id = ?',
        whereArgs: [opnameId],
        limit: 1,
      );
      
      if (opnamesList.isEmpty) {
        throw Exception('Stock opname not found');
      }
      
      final opnameMap = opnamesList.first;
      final opname = StockOpname(
        id: opnameMap['id'],
        branchId: opnameMap['branch_id'],
        userId: opnameMap['user_id'],
        referenceNumber: opnameMap['reference_number'],
        opnameDate: opnameMap['opname_date'],
        status: opnameMap['status'],
        notes: opnameMap['notes'] ?? '',
      );
      
      // Load opname items - using query instead of getStockOpnameItems
      final itemsList = await _databaseService.query(
        'stock_opname_items',
        where: 'stock_opname_id = ?',
        whereArgs: [opnameId],
      );
      
      final items = await Future.wait(itemsList.map((item) async {
        final productId = item['product_id'];
        final products = await _databaseService.query(
          'products',
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        
        if (products.isEmpty) {
          return null;
        }
        
        final product = products.first;
        
        return StockOpnameItem(
          id: item['id'],
          stockOpnameId: opnameId,
          productId: productId,
          productName: product['name'],
          productSku: product['sku'],
          systemStock: (item['system_stock'] as num?)?.toDouble() ?? 0.0,
          physicalStock: (item['physical_stock'] as num?)?.toDouble() ?? 0.0,
          difference: (item['difference'] as num?)?.toDouble() ?? 0.0,
          notes: item['notes'] ?? '',
        );
      }));
      
      final validItems = items.whereType<StockOpnameItem>().toList();
      
      // Create product list for filtering
      final products = validItems.map((item) => Product(
        id: item.productId,
        sku: item.productSku,
        barcode: null, // We don't have barcode from this query
        name: item.productName,
        categoryId: 0, 
        category: '', 
        buyingPrice: 0, 
        sellingPrice: 0,
        createdAt: '',
        updatedAt: '',
      )).toList();

      if (mounted) {
        setState(() {
          _currentOpname = opname;
          _opnameItems = validItems;
          _filteredProducts = products;
          _selectedBranchId = opname.branchId;
          _isLoading = false;
          _currentTabIndex = 1; // Switch to Count tab
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error loading stock opname: $e');
      }
    }
  }

  Future<void> _scanBarcode() async {
    try {
      // Removed unused variable 'currentContext'
      await Navigator.of(context).push(
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
                    if (mounted) {
                      _processBarcodeResult(barcode);
                    }
                  }
                }
              },
            ),
          ),
        ),
      );
    } catch (e) {
      logger.e('Error scanning barcode: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error scanning barcode'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processBarcodeResult(String barcode) async {
    // Search for product with matching SKU or barcode
    final matchingItems = _opnameItems.where(
      (item) => item.productSku == barcode
    ).toList();
    
    if (matchingItems.isNotEmpty) {
      // If found by SKU, show the count dialog
      _showCountDialog(matchingItems.first);
    } else {
      // Jika tidak ditemukan berdasarkan SKU, cari barcode di database
      await _searchProductByBarcode(barcode);
    }
  }

  // Metode untuk mencari produk berdasarkan barcode
  Future<void> _searchProductByBarcode(String barcode) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Cari produk berdasarkan barcode atau SKU
      final products = await _databaseService.query(
        'products',
        where: 'barcode = ? OR sku = ?',
        whereArgs: [barcode, barcode],
      );
      
      if (!mounted) return;
      
      if (products.isNotEmpty) {
        final product = products.first;
        final productId = product['id'] as int;
        
        // Cek apakah produk sudah ada di opname items
        final existingItemIndex = _opnameItems.indexWhere(
          (item) => item.productId == productId,
        );
        
        if (existingItemIndex >= 0) {
          // Produk sudah ada di daftar opname
          _showCountDialog(_opnameItems[existingItemIndex]);
        } else {
          // Produk ditemukan di database tapi belum ada di opname items
          // Buat item opname baru untuk produk ini
          await _addProductToOpname(product);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk dengan barcode/SKU ini tidak ditemukan di database'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat mencari produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Metode untuk menambahkan produk baru ke opname
  Future<void> _addProductToOpname(Map<String, dynamic> product) async {
    if (_currentOpname == null) return;
    
    final productId = product['id'] as int;
    
    try {
      // Cek inventori untuk produk ini di cabang yang dipilih
      final inventoryItems = await _databaseService.query(
        'inventory',
        where: 'product_id = ? AND branch_id = ?',
        whereArgs: [productId, _currentOpname!.branchId],
        limit: 1,
      );
      
      if (!mounted) return;
      
      // Default quantity ke 0 jika tidak ada inventori
      final double systemStock = inventoryItems.isNotEmpty 
          ? (inventoryItems.first['quantity'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      
      // Buat stock opname item baru
      final newItem = StockOpnameItem(
        id: 0,
        stockOpnameId: _currentOpname!.id,
        productId: productId,
        productName: product['name'] as String,
        productSku: product['sku'] as String,
        systemStock: systemStock,
        physicalStock: 0.0, // Default 0 untuk memaksa pengguna mengisi nilai
        difference: -systemStock, // Default selisih negatif
        notes: 'Produk ditambahkan saat scanning',
      );
      
      // Tambahkan produk ke model
      final newProduct = Product(
        id: productId,
        sku: product['sku'] as String,
        barcode: product['barcode'] as String?,
        name: product['name'] as String,
        categoryId: (product['category_id'] as num?)?.toInt() ?? 0,
        category: '',
        buyingPrice: (product['buying_price'] as num?)?.toDouble() ?? 0.0,
        sellingPrice: (product['selling_price'] as num?)?.toDouble() ?? 0.0,
        createdAt: product['created_at'] as String? ?? DateTime.now().toIso8601String(),
        updatedAt: product['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      );
      
      // Update state
      setState(() {
        _opnameItems.add(newItem);
        _filteredProducts.add(newProduct);
        _hasChanges = true;
      });
      
      // Langsung tampilkan dialog untuk menghitung item ini
      _showCountDialog(newItem);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk "${newProduct.name}" ditambahkan ke stock opname'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menambahkan produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCountDialog(StockOpnameItem item) async {
    final TextEditingController controller = TextEditingController(
      text: item.physicalStock.toString(),
    );
    final TextEditingController notesController = TextEditingController(
      text: item.notes,
    );
    
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Count Inventory'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product: ${item.productName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('SKU: ${item.productSku}'),
              const SizedBox(height: 8),
              Text('System Stock: ${item.systemStock}'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Physical Count *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final double physicalCount = double.tryParse(controller.text) ?? 0;
                _updateItemCount(item, physicalCount, notesController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid count')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _updateItemCount(StockOpnameItem item, double physicalCount, String notes) {
    setState(() {
      final index = _opnameItems.indexWhere((i) => i.productId == item.productId);
      if (index >= 0) {
        final difference = physicalCount - item.systemStock;
        _opnameItems[index] = item.copyWith(
          physicalStock: physicalCount,
          difference: difference,
          notes: notes,
        );
        _hasChanges = true;
      }
    });
  }

  Future<void> _saveOpname() async {
    if (_currentOpname == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update stock opname items - using update and insert instead of updateStockOpnameItems
      for (var item in _opnameItems) {
        if (item.id > 0) {
          // Update existing item
          await _databaseService.update(
            'stock_opname_items',
            {
              'physical_stock': item.physicalStock,
              'difference': item.difference,
              'notes': item.notes,
              'updated_at': DateTime.now().toIso8601String(),
            },
            'id = ?',
            [item.id],
          );
        } else {
          // Insert new item
          final now = DateTime.now().toIso8601String();
          await _databaseService.insert(
            'stock_opname_items',
            {
              'stock_opname_id': item.stockOpnameId,
              'product_id': item.productId,
              'system_stock': item.systemStock,
              'physical_stock': item.physicalStock,
              'difference': item.difference,
              'notes': item.notes,
              'created_at': now,
              'updated_at': now,
            },
          );
        }
      }
      
      // Check if any changes were made
      final hasDiscrepancies = _opnameItems.any((item) => item.difference != 0);
      
      if (mounted) {
        setState(() {
          _hasChanges = false;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hasDiscrepancies 
                ? 'Stock opname saved with discrepancies' 
                : 'Stock opname saved'),
            backgroundColor: hasDiscrepancies ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error saving stock opname: $e');
      }
    }
  }

  Future<void> _completeOpname() async {
    if (_currentOpname == null) return;

    // First save any pending changes
    if (_hasChanges) {
      await _saveOpname();
    }

    // Ask for confirmation
    final BuildContext currentContext = context;
    final bool? confirm = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Complete Stock Opname'),
        content: const Text(
          'This will adjust inventory to match the physical counts you recorded. '
          'This action cannot be undone. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update stock opname status to completed
      await _databaseService.update(
        'stock_opname',
        {
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        'id = ?',
        [_currentOpname!.id],
      );
      
      // Apply inventory adjustments - using direct database operations
      for (var item in _opnameItems) {
        if (item.difference != 0) {
          // Update inventory quantity
          final inventoryItems = await _databaseService.query(
            'inventory',
            where: 'product_id = ? AND branch_id = ?',
            whereArgs: [item.productId, _currentOpname!.branchId],
            limit: 1,
          );
          
          if (inventoryItems.isEmpty) {
            // Create new inventory record if doesn't exist
            await _databaseService.insert(
              'inventory',
              {
                'product_id': item.productId,
                'branch_id': _currentOpname!.branchId,
                'quantity': item.physicalStock,
                'reserved_quantity': 0.0,
                'min_stock_level': 0.0,
                'max_stock_level': 0.0,
                'reorder_point': 0.0,
                'last_stock_update': DateTime.now().toIso8601String(),
                'last_counting_date': DateTime.now().toIso8601String(),
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
            );
          } else {
            // Update existing inventory record
            await _databaseService.update(
              'inventory',
              {
                'quantity': item.physicalStock,
                'last_counting_date': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
              'product_id = ? AND branch_id = ?',
              [item.productId, _currentOpname!.branchId],
            );
          }
          
          // Add inventory transaction record
          await _databaseService.insert(
            'inventory_transactions',
            {
              'transaction_date': DateTime.now().toIso8601String(),
              'reference_id': _currentOpname!.id,
              'reference_type': 'stock_opname',
              'product_id': item.productId,
              'branch_id': _currentOpname!.branchId,
              'transaction_type': item.difference > 0 ? 'stock_addition' : 'stock_reduction',
              'quantity': item.difference.abs(),
              'notes': 'Stock opname adjustment: ${item.notes}',
              'user_id': _currentOpname!.userId,
              'created_at': DateTime.now().toIso8601String(),
            },
          );
        }
      }
      
      // Reset the screen
      if (mounted) {
        setState(() {
          _currentOpname = null;
          _opnameItems = [];
          _filteredProducts = [];
          _isLoading = false;
          _currentTabIndex = 0; // Switch back to List tab
        });
        
        // Refresh data
        _initializeData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock opname completed and inventory adjusted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error completing stock opname: $e');
      }
    }
  }

  Future<void> _cancelOpname() async {
    if (_currentOpname == null) return;

    final BuildContext currentContext = context;
    final bool? confirm = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Stock Opname'),
        content: const Text(
          'This will delete the current stock opname and all counts. '
          'This action cannot be undone. Continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Delete stock opname items
      await _databaseService.delete(
        'stock_opname_items',
        'stock_opname_id = ?',
        [_currentOpname!.id],
      );
      
      // Delete stock opname
      await _databaseService.delete(
        'stock_opname',
        'id = ?',
        [_currentOpname!.id],
      );
      
      // Reset the screen
      if (mounted) {
        setState(() {
          _currentOpname = null;
          _opnameItems = [];
          _filteredProducts = [];
          _isLoading = false;
          _currentTabIndex = 0; // Switch back to List tab
        });
        
        // Refresh data
        _initializeData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock opname cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error cancelling stock opname: $e');
      }
    }
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredProducts = _opnameItems.map((item) => Product(
          id: item.productId,
          sku: item.productSku,
          barcode: null,
          name: item.productName,
          categoryId: 0,
          category: '',
          buyingPrice: 0,
          sellingPrice: 0,
          createdAt: '',
          updatedAt: '',
        )).toList();
      });
      return;
    }

    final query = _searchQuery.toLowerCase();
    setState(() {
      _filteredProducts = _opnameItems
          .where((item) => 
              item.productName.toLowerCase().contains(query) ||
              item.productSku.toLowerCase().contains(query))
          .map((item) => Product(
            id: item.productId,
            sku: item.productSku,
            barcode: null,
            name: item.productName,
            categoryId: 0,
            category: '',
            buyingPrice: 0,
            sellingPrice: 0,
            createdAt: '',
            updatedAt: '',
          ))
          .toList();
    });
  }


  // UI Builders
  Widget _buildOngoingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Branch selection
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Branch:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                value: _selectedBranchId,
                items: _branches.map((branch) {
                  return DropdownMenuItem<int>(
                    value: branch['id'] as int,
                    child: Text(branch['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBranchId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createNewOpname,
                  icon: const Icon(Icons.add),
                  label: const Text('Start New Stock Opname'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const Divider(),
        
        // Ongoing opnames list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Ongoing Stock Opnames',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        
        Expanded(
          child: _ongoingOpnames.isEmpty
              ? const Center(
                  child: Text('No ongoing stock opnames'),
                )
              : ListView.builder(
                  itemCount: _ongoingOpnames.length,
                  itemBuilder: (context, index) {
                    final opname = _ongoingOpnames[index];
                    final branchMap = _branches
                        .firstWhere((b) => b['id'] == opname.branchId, 
                                   orElse: () => {'name': 'Unknown'});
                    final branchName = branchMap['name'] ?? 'Unknown';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        title: Text(opname.referenceNumber),
                        subtitle: Text(
                          'Branch: $branchName\n'
                          'Date: ${opname.opnameDate.substring(0, 10)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _loadExistingOpname(opname.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCountTab() {
    if (_currentOpname == null) {
      return const Center(
        child: Text('No active stock opname. Start a new one from the List tab.'),
      );
    }

    // Find the branch name
    final branchMap = _branches
        .firstWhere((b) => b['id'] == _currentOpname!.branchId, 
                   orElse: () => {'name': 'Unknown'});
    final branchName = branchMap['name'] ?? 'Unknown';
    
    // Count statistics
    final totalItems = _opnameItems.length;
    final countedItems = _opnameItems.where((item) => 
        item.physicalStock != item.systemStock || item.notes.isNotEmpty).length;
    final discrepancyItems = _opnameItems.where((item) => item.difference != 0).length;
    
    return Column(
      children: [
        // Stock Opname Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).primaryColor.withAlpha(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Opname: ${_currentOpname!.referenceNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text('Branch: $branchName'),
              Text('Date: ${_currentOpname!.opnameDate.substring(0, 10)}'),
              Text('Status: ${_currentOpname!.status.toUpperCase()}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Items: $totalItems'),
                  Text('Counted: $countedItems'),
                  Text(
                    'Discrepancies: $discrepancyItems',
                    style: TextStyle(
                      color: discrepancyItems > 0 ? Colors.red : null,
                      fontWeight: discrepancyItems > 0 ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search Products',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterProducts();
              });
            },
          ),
        ),
        
        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Barcode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasChanges ? _saveOpname : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Progress'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _completeOpname,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cancelOpname,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Products List
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No products found.'),
                      if (_searchQuery.isNotEmpty)
                        Text(
                          'Try a different search term.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final opnameItem = _opnameItems.firstWhere(
                      (item) => item.productId == product.id,
                      orElse: () => StockOpnameItem(
                        id: 0,
                        stockOpnameId: _currentOpname!.id,
                        productId: product.id,
                        productName: product.name,
                        productSku: product.sku,
                        systemStock: 0,
                        physicalStock: 0,
                        difference: 0,
                        notes: '',
                      ),
                    );
                    
                    final isCounted = opnameItem.physicalStock != opnameItem.systemStock || 
                                   opnameItem.notes.isNotEmpty;
                    final hasDiscrepancy = opnameItem.difference != 0;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      color: hasDiscrepancy 
                          ? Colors.red[50] 
                          : (isCounted ? Colors.green[50] : null),
                      child: ListTile(
                        title: Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: hasDiscrepancy ? FontWeight.bold : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SKU: ${product.sku}'),
                            if (product.barcode != null && product.barcode!.isNotEmpty)
                              Text('Barcode: ${product.barcode}'),
                            Row(
                              children: [
                                Text('System: ${opnameItem.systemStock}'),
                                const SizedBox(width: 16),
                                if (isCounted)
                                  Text(
                                    'Physical: ${opnameItem.physicalStock}',
                                    style: TextStyle(
                                      color: hasDiscrepancy ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            if (hasDiscrepancy)
                              Text(
                                'Difference: ${opnameItem.difference > 0 ? '+' : ''}${opnameItem.difference}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (opnameItem.notes.isNotEmpty)
                              Text('Note: ${opnameItem.notes}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showCountDialog(opnameItem),
                        ),
                        onTap: () => _showCountDialog(opnameItem),
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
    final TabController tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _currentTabIndex,
    );
    
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stock Opname'),
          bottom: TabBar(
            controller: tabController,
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            tabs: const [
              Tab(text: 'LIST'),
              Tab(text: 'COUNT'),
            ],
          ),
        ),
        body: _isInitializing
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: tabController,
                children: [
                  _buildOngoingTab(),
                  _buildCountTab(),
                ],
              ),
      ),
    );
  }
}