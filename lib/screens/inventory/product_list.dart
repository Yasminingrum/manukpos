// product_list.dart
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/database_service.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_drawer.dart';
import '../../config/routes.dart';

class ProductListScreen extends StatefulWidget {
  static const routeName = '/products';

  const ProductListScreen({super.key});

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Filtering and sorting options
  int? _selectedCategoryId;
  String _sortBy = 'name'; // Default sort by name
  bool _sortAscending = true;
  bool _showActiveOnly = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    await _loadCategories();
    await _loadProducts();
  }
  
  Future<void> _loadCategories() async {
    try {
      final categories = await _databaseService.getAllCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading categories: $e');
    }
  }
  
  Future<void> _loadProducts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Use the query method instead of getAllProducts which isn't defined
      final products = await _databaseService.query('products');
      
      setState(() {
        _products = products;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading products: $e';
        _isLoading = false;
      });
    }
  }
  
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_products);
    
    // Apply category filter
    if (_selectedCategoryId != null) {
      filtered = filtered.where((p) => p['category_id'] == _selectedCategoryId).toList();
    }
    
    // Apply active only filter
    if (_showActiveOnly) {
      filtered = filtered.where((p) => p['is_active'] == 1).toList();
    }
    
    // Apply search filter if text is present
    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      filtered = filtered.where((p) => 
        p['name'].toString().toLowerCase().contains(searchText) || 
        p['sku'].toString().toLowerCase().contains(searchText) ||
        (p['barcode'] != null && p['barcode'].toString().toLowerCase().contains(searchText)) ||
        (p['tags'] != null && p['tags'].toString().toLowerCase().contains(searchText))
      ).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      int result = 0;
      switch (_sortBy) {
        case 'name':
          result = a['name'].toString().compareTo(b['name'].toString());
          break;
        case 'sku':
          result = a['sku'].toString().compareTo(b['sku'].toString());
          break;
        case 'category':
          // Get category names from categories list
          String aCategoryName = '';
          String bCategoryName = '';
          
          final aCategoryId = a['category_id'];
          final bCategoryId = b['category_id'];
          
          if (_categories.isNotEmpty) {
            final aCategory = _categories.firstWhere(
              (c) => c.id == aCategoryId,
              orElse: () => Category(id: 0, name: 'Unknown', code: null, description: null, level: 1, parentId: null, path: null, createdAt: '', updatedAt: '')
            );
            
            final bCategory = _categories.firstWhere(
              (c) => c.id == bCategoryId,
              orElse: () => Category(id: 0, name: 'Unknown', code: null, description: null, level: 1, parentId: null, path: null, createdAt: '', updatedAt: '')
            );
            
            aCategoryName = aCategory.name;
            bCategoryName = bCategory.name;
          }
          
          result = aCategoryName.compareTo(bCategoryName);
          break;
        case 'price':
          final aPrice = a['selling_price'] ?? 0.0;
          final bPrice = b['selling_price'] ?? 0.0;
          result = aPrice.compareTo(bPrice);
          break;
        default:
          result = a['name'].toString().compareTo(b['name'].toString());
      }
      
      return _sortAscending ? result : -result;
    });
    
    setState(() {
      _filteredProducts = filtered;
    });
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Products'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<int?>(
                  isExpanded: true,
                  value: _selectedCategoryId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ..._categories.map((c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name),
                    )),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
                
                const Divider(),
                const Text('Sort By:', style: TextStyle(fontWeight: FontWeight.bold)),
                
                RadioListTile<String>(
                  title: const Text('Name'),
                  value: 'name',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('SKU'),
                  value: 'sku',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Category'),
                  value: 'category',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Price'),
                  value: 'price',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setDialogState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Order: '),
                    TextButton.icon(
                      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                      label: Text(_sortAscending ? 'Ascending' : 'Descending'),
                      onPressed: () {
                        setDialogState(() {
                          _sortAscending = !_sortAscending;
                        });
                      },
                    ),
                  ],
                ),
                
                const Divider(),
                
                SwitchListTile(
                  title: const Text('Show Active Products Only'),
                  value: _showActiveOnly,
                  onChanged: (value) {
                    setDialogState(() {
                      _showActiveOnly = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('RESET'),
              onPressed: () {
                setDialogState(() {
                  _selectedCategoryId = null;
                  _sortBy = 'name';
                  _sortAscending = true;
                  _showActiveOnly = true;
                });
              },
            ),
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('APPLY'),
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _confirmDeleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product['name']}"? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Use the database delete method directly
        await _databaseService.delete(
          'products',
          'id = ?',
          [product['id']],
        );
        
        setState(() {
          _products.removeWhere((p) => p['id'] == product['id']);
          _isLoading = false;
        });
        
        _applyFilters();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product['name']} has been deleted'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error deleting product: $e');
      }
    }
  }
  
  Widget _buildProductItem(Map<String, dynamic> product) {
    // Determine if the product has a discount
    final hasDiscount = product['discount_price'] != null && 
                        product['discount_price'] < product['selling_price'];
                        
    // Calculate discount percentage if applicable
    String? discountPercentage;
    if (hasDiscount) {
      final discount = product['selling_price'] - product['discount_price'];
      final percentage = (discount / product['selling_price']) * 100;
      discountPercentage = percentage.toStringAsFixed(0);
    }
    
    // Get category name
    String categoryName = 'Unknown';
    if (_categories.isNotEmpty) {
      final category = _categories.firstWhere(
        (c) => c.id == product['category_id'],
        orElse: () => Category(id: 0, name: 'Unknown', code: null, description: null, level: 1, parentId: null, path: null, createdAt: '', updatedAt: '')
      );
      categoryName = category.name;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: product['image_url'] != null
                        ? DecorationImage(
                            image: NetworkImage(product['image_url']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product['image_url'] == null
                      ? Icon(
                          product['is_service'] == 1 ? Icons.miscellaneous_services : Icons.inventory_2,
                          size: 40,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${product['sku']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: $categoryName',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              'Rp ${product['selling_price'].toStringAsFixed(0)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-$discountPercentage%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            'Rp ${(hasDiscount ? product['discount_price'] : product['selling_price']).toStringAsFixed(0)}',
                            style: TextStyle(
                              color: hasDiscount ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: hasDiscount ? 14 : 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status indicators
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (product['is_active'] != 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'INACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (product['is_service'] == 1)
                      Container(
                        margin: EdgeInsets.only(top: product['is_active'] == 1 ? 0 : 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SERVICE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (product['is_featured'] == 1)
                      Container(
                        margin: EdgeInsets.only(
                          top: (product['is_active'] == 1 && product['is_service'] != 1) ? 0 : 4
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            const Divider(),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.inventory),
                  tooltip: 'View Inventory',
                  onPressed: () {
                    Navigator.pushNamed(
                      context, 
                      '/product/inventory',
                      arguments: product['id'],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Product',
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRouter.productForm,
                      arguments: product['id'],
                    );
                    
                    if (result == true) {
                      _loadProducts();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  tooltip: 'Delete Product',
                  onPressed: () => _confirmDeleteProduct(product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Products',
                  hintText: 'Enter name, SKU or barcode',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _applyFilters();
                },
              ),
            ),
            
            // Filter chips
            if (_selectedCategoryId != null || _sortBy != 'name' || !_sortAscending || !_showActiveOnly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_selectedCategoryId != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(
                              'Category: ${_categories.firstWhere((c) => c.id == _selectedCategoryId).name}',
                            ),
                            onDeleted: () {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      if (_sortBy != 'name' || !_sortAscending)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(
                              'Sort: ${_sortBy.substring(0, 1).toUpperCase()}${_sortBy.substring(1)} (${_sortAscending ? 'Asc' : 'Desc'})',
                            ),
                            onDeleted: () {
                              setState(() {
                                _sortBy = 'name';
                                _sortAscending = true;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      if (!_showActiveOnly)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: const Text('Including Inactive'),
                            onDeleted: () {
                              setState(() {
                                _showActiveOnly = true;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategoryId = null;
                            _sortBy = 'name';
                            _sortAscending = true;
                            _showActiveOnly = true;
                            _searchController.clear();
                          });
                          _applyFilters();
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Error message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            // Product list
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _products.isEmpty
                                ? 'No products available'
                                : 'No products match your filters',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          if (_products.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategoryId = null;
                                  _showActiveOnly = true;
                                  _searchController.clear();
                                });
                                _applyFilters();
                              },
                              child: const Text('Clear filters'),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (ctx, index) => _buildProductItem(_filteredProducts[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRouter.productForm);
          if (result == true) {
            _loadProducts();
          }
        },
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }
}