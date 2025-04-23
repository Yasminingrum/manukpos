// screens/reports/inventory_report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/product.dart';
import '../../models/inventory.dart';
import '../../models/inventory_movement.dart';
import '../../services/product_service.dart';
import '../../services/inventory_service.dart';
import '../../utils/formatters.dart';
import '../../utils/export_utils.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/chart/pie_chart.dart';
import '../../widgets/chart/bar_chart.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _filterBy = 'all'; // 'all', 'low_stock', 'out_of_stock', 'inactive'
  int? _selectedCategoryId;
  String _searchQuery = '';

  // Data containers
  List<InventoryItem> _inventoryItems = [];
  List<Product> _products = [];
  List<InventoryMovement> _movements = [];
  Map<String, dynamic> _inventorySummary = {};
  List<Map<String, dynamic>> _categoryData = [];
  List<Map<String, dynamic>> _movementData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      final inventoryService = Provider.of<InventoryService>(context, listen: false);
      
      // Load product data
      final products = await productService.getProducts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
        isActive: _filterBy == 'inactive' ? false : null,
      );
      
      // Load inventory data
      final inventoryItems = await inventoryService.getInventoryItems(
        lowStockOnly: _filterBy == 'low_stock' ? true : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
      );
      
      // Load inventory movements from inventory transactions
      // Akses database melalui _databaseService di InventoryService
      final db = await inventoryService._databaseService.database;
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();
      
      final movementsQuery = '''
      SELECT it.id, it.product_id, p.name as product_name, p.sku as product_sku,
             it.transaction_date as date, it.transaction_type as type,
             it.quantity, it.reference_type, it.reference_id, it.unit_price, it.notes,
             it.user_id, it.branch_id
      FROM inventory_transactions it
      JOIN products p ON it.product_id = p.id
      WHERE it.transaction_date BETWEEN ? AND ?
      ORDER BY it.transaction_date DESC
      ''';
      
      final movementsResult = await db.rawQuery(
        movementsQuery, 
        [startDate.toIso8601String(), endDate.toIso8601String()]
      );
      
      final movements = movementsResult.map((map) {
        return InventoryMovement(
          id: map['id'] as int,
          productId: map['product_id'] as int,
          productName: map['product_name'] as String,
          productSku: map['product_sku'] as String,
          date: DateTime.parse(map['date'] as String),
          type: map['type'] as String,
          quantity: map['quantity'] is int ? 
            (map['quantity'] as int).toDouble() : (map['quantity'] as double),
          referenceType: map['reference_type'] as String?,
          referenceId: map['reference_id'] as int?,
          unitPrice: map['unit_price'] != null ? 
            (map['unit_price'] is int ? 
              (map['unit_price'] as int).toDouble() : 
              (map['unit_price'] as double)) : null,
          notes: map['notes'] as String?,
          userId: map['user_id'] as int?,
          branchId: map['branch_id'] as int,
          createdAt: null,
          syncStatus: null,
        );
      }).toList();
      
      // Load inventory statistics/summary
      final summary = await inventoryService.getInventoryStatistics();
      
      // Process data for charts
      final categoryData = _processCategoryData(products);
      final movementData = _processMovementData(movements);
      
      setState(() {
        _products = products;
        _inventoryItems = inventoryItems;
        _movements = movements;
        _inventorySummary = summary;
        _categoryData = categoryData;
        _movementData = movementData;
        _isLoading = false;
      });
    } catch (e) {
      // Guard untuk memastikan widget masih di-mount sebelum update state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory data: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _processCategoryData(List<Product> products) {
    // Create a map to count products by category
    final Map<String, int> categoryCounts = {};
    final Map<String, double> categoryValues = {};
    
    for (var product in products) {
      final category = product.category;
      
      // Count products per category
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      
      // Calculate inventory value per category
      final productInventory = _inventoryItems.firstWhere(
        (item) => item.productId == product.id,
        orElse: () => InventoryItem(
          id: 0,
          productId: product.id,
          branchId: 0,
          branchName: '',
          quantity: 0,
          minStockLevel: 0,
          createdAt: '',
          updatedAt: '',
        ),
      );
      
      final inventoryValue = productInventory.quantity * product.buyingPrice;
      categoryValues[category] = (categoryValues[category] ?? 0) + inventoryValue;
    }
    
    // Convert to list format for chart
    return categoryValues.entries.map((entry) => {
      'category': entry.key,
      'count': categoryCounts[entry.key] ?? 0,
      'value': entry.value,
    }).toList()
      ..sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));
  }

  List<Map<String, dynamic>> _processMovementData(List<InventoryMovement> movements) {
    // Group movements by date and type
    final Map<String, Map<String, double>> movementsByDate = {};
    
    for (var movement in movements) {
      final dateStr = DateFormat('yyyy-MM-dd').format(movement.date);
      
      if (!movementsByDate.containsKey(dateStr)) {
        movementsByDate[dateStr] = {'in': 0, 'out': 0};
      }
      
      if (movement.type == InventoryMovement.TYPE_IN) {
        movementsByDate[dateStr]!['in'] = (movementsByDate[dateStr]!['in'] ?? 0) + movement.quantity;
      } else {
        movementsByDate[dateStr]!['out'] = (movementsByDate[dateStr]!['out'] ?? 0) + movement.quantity;
      }
    }
    
    // Convert to list format for chart
    return movementsByDate.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      return {
        'date': date,
        'display_date': DateFormat('dd MMM').format(date),
        'in': entry.value['in'] ?? 0,
        'out': entry.value['out'] ?? 0,
      };
    }).toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  Future<void> _exportToExcel() async {
    try {
      // Prepare headers and data
      final headers = ['SKU', 'Product Name', 'Category', 'Stock Qty', 'Min Stock', 'Value', 'Status'];
      
      // Combine product and inventory data
      final List<List<dynamic>> data = [];
      
      for (var product in _products) {
        final inventory = _inventoryItems.firstWhere(
          (item) => item.productId == product.id,
          orElse: () => InventoryItem(
            id: 0,
            productId: product.id,
            branchId: 0,
            branchName: '',
            quantity: 0,
            minStockLevel: 0,
            createdAt: '',
            updatedAt: '',
          ),
        );
        
        final inventoryValue = inventory.quantity * product.buyingPrice;
        String status = 'Normal';
        
        if (inventory.quantity <= 0) {
          status = 'Out of Stock';
        } else if (inventory.isLowStock) {
          status = 'Low Stock';
        }
        
        data.add([
          product.sku,
          product.name,
          product.category,
          inventory.quantity,
          inventory.minStockLevel,
          inventoryValue,
          status,
        ]);
      }
      
      // Export to Excel
      final fileName = 'Inventory_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
      final file = await ExportUtils.exportToExcel(data, headers, fileName);
      
      // Share the file
      await ExportUtils.shareFile(file, subject: 'Inventory Report');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventory report exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export report: $e')),
        );
      }
    }
  }

  Future<void> _exportToPDF() async {
    try {
      // Prepare headers and data
      final headers = ['SKU', 'Product', 'Category', 'Qty', 'Min Stock', 'Value', 'Status'];
      
      // Combine product and inventory data
      final List<List<dynamic>> data = [];
      
      for (var product in _products) {
        final inventory = _inventoryItems.firstWhere(
          (item) => item.productId == product.id,
          orElse: () => InventoryItem(
            id: 0,
            productId: product.id,
            branchId: 0,
            branchName: '',
            quantity: 0,
            minStockLevel: 0,
            createdAt: '',
            updatedAt: '',
          ),
        );
        
        final inventoryValue = inventory.quantity * product.buyingPrice;
        String status = 'Normal';
        
        if (inventory.quantity <= 0) {
          status = 'Out of Stock';
        } else if (inventory.isLowStock) {
          status = 'Low Stock';
        }
        
        data.add([
          product.sku,
          product.name,
          product.category,
          inventory.quantity,
          inventory.minStockLevel,
          Formatters.formatCurrency(inventoryValue),
          status,
        ]);
      }
      
      // Export to PDF
      final fileName = 'Inventory_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}';
      final title = 'Inventory Report';
      final subtitle = 'Generated on ${DateFormat('dd MMM yyyy').format(DateTime.now())}';
      
      final file = await ExportUtils.exportToPDF(data, headers, fileName, title: title, subtitle: subtitle);
      
      // Share the file
      await ExportUtils.shareFile(file, subject: 'Inventory Report');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventory report exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Inventory Report',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
            tooltip: 'Filter',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'excel') {
                _exportToExcel();
              } else if (value == 'pdf') {
                _exportToPDF();
              } else if (value == 'refresh') {
                _loadData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export to Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export to PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const LoadingIndicator()
          : Column(
              children: [
                // Filter indicator
                if (_filterBy != 'all' || _selectedCategoryId != null || _searchQuery.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: AppTheme.primaryColor.withAlpha(26), // 10% opacity = 26 as alpha
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _buildFilterDescription(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterBy = 'all';
                              _selectedCategoryId = null;
                              _searchQuery = '';
                            });
                            _loadData();
                          },
                          child: const Text(
                            'Clear Filters',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Products',
                          value: '${_inventorySummary['total_products'] ?? 0}',
                          icon: Icons.inventory_2,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Low Stock',
                          value: '${_inventorySummary['low_stock_count'] ?? 0}',
                          icon: Icons.warning,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Out of Stock',
                          value: '${_inventorySummary['out_of_stock_count'] ?? 0}',
                          icon: Icons.remove_shopping_cart,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Inventory Value',
                          value: Formatters.formatCurrency(_inventorySummary['total_value'] ?? 0),
                          icon: Icons.monetization_on,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tab bar
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'SUMMARY'),
                    Tab(text: 'INVENTORY'),
                    Tab(text: 'MOVEMENTS'),
                  ],
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildInventoryTab(),
                      _buildMovementsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _buildFilterDescription() {
    List<String> filters = [];
    
    if (_filterBy == 'low_stock') {
      filters.add('Low Stock');
    } else if (_filterBy == 'out_of_stock') {
      filters.add('Out of Stock');
    } else if (_filterBy == 'inactive') {
      filters.add('Inactive Products');
    }
    
    if (_selectedCategoryId != null) {
      // Find the category name
      final product = _products.firstWhere(
        (p) => p.categoryId == _selectedCategoryId,
        orElse: () => Product(
          id: 0,
          sku: '',
          name: '',
          categoryId: 0,
          category: 'Unknown',
          buyingPrice: 0,
          sellingPrice: 0,
          createdAt: '',
          updatedAt: '',
        ),
      );
      filters.add('Category: ${product.category}');
    }
    
    if (_searchQuery.isNotEmpty) {
      filters.add('Search: "$_searchQuery"');
    }
    
    return filters.join(' | ');
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildFilterDialog(),
    );
    
    if (result != null) {
      setState(() {
        _filterBy = result['filterBy'] as String;
        _selectedCategoryId = result['categoryId'] as int?;
        _searchQuery = result['search'] as String;
      });
      _loadData();
    }
  }

  Widget _buildFilterDialog() {
    String tempFilterBy = _filterBy;
    int? tempCategoryId = _selectedCategoryId;
    String tempSearch = _searchQuery;
    
    return AlertDialog(
      title: const Text('Filter Inventory'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: const Text('All Products'),
                  value: 'all',
                  groupValue: tempFilterBy,
                  onChanged: (value) {
                    setState(() {
                      tempFilterBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Low Stock'),
                  value: 'low_stock',
                  groupValue: tempFilterBy,
                  onChanged: (value) {
                    setState(() {
                      tempFilterBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Out of Stock'),
                  value: 'out_of_stock',
                  groupValue: tempFilterBy,
                  onChanged: (value) {
                    setState(() {
                      tempFilterBy = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Inactive Products'),
                  value: 'inactive',
                  groupValue: tempFilterBy,
                  onChanged: (value) {
                    setState(() {
                      tempFilterBy = value!;
                    });
                  },
                ),
                const Divider(),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButtonFormField<int?>(
                  value: tempCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Select Category',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ..._getCategoryDropdownItems(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      tempCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Search',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by product name or SKU',
                    prefixIcon: Icon(Icons.search),
                  ),
                  // Fix: initialValue is not valid for TextField
                  controller: TextEditingController(text: tempSearch),
                  onChanged: (value) {
                    tempSearch = value;
                  },
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'filterBy': tempFilterBy,
              'categoryId': tempCategoryId,
              'search': tempSearch,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  List<DropdownMenuItem<int>> _getCategoryDropdownItems() {
    // Extract unique categories from products
    final Map<int, String> categories = {};
    
    for (var product in _products) {
      categories[product.categoryId] = product.category;
    }
    
    return categories.entries
        .map((entry) => DropdownMenuItem<int>(
              value: entry.key,
              child: Text(entry.value),
            ))
        .toList();
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return _products.isEmpty
        ? const EmptyState(
            icon: Icons.inventory_2,
            message: 'No inventory data available',
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory Value by Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    data: _categoryData,
                    labelKey: 'category',
                    valueKey: 'value',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Inventory Movement (Last 30 Days)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    data: _movementData,
                    xAxisKey: 'display_date',
                    yAxisKey: 'in',
                    barColor: Colors.blue,
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildInventoryTab() {
    if (_products.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2,
        message: 'No inventory data available',
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search products...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              if (value.length >= 3 || value.isEmpty) {
                _loadData();
              }
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final inventory = _inventoryItems.firstWhere(
                (item) => item.productId == product.id,
                orElse: () => InventoryItem(
                  id: 0,
                  productId: product.id,
                  branchId: 0,
                  branchName: '',
                  quantity: 0,
                  minStockLevel: 0,
                  createdAt: '',
                  updatedAt: '',
                ),
              );
              
              final stockStatus = inventory.quantity <= 0
                  ? 'Out of Stock'
                  : inventory.isLowStock
                      ? 'Low Stock'
                      : 'In Stock';
              
              final inventoryValue = inventory.quantity * product.buyingPrice;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStockStatusColor(stockStatus),
                    child: Text(
                      inventory.quantity.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.sku} | ${product.category} | Min: ${inventory.minStockLevel}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(inventoryValue),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        stockStatus,
                        style: TextStyle(
                          color: _getStockStatusColor(stockStatus),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to product detail page
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovementsTab() {
    if (_movements.isEmpty) {
      return const EmptyState(
        icon: Icons.sync_alt,
        message: 'No inventory movements available for the last 30 days',
      );
    }
    
    return ListView.builder(
      itemCount: _movements.length,
      itemBuilder: (context, index) {
        final movement = _movements[index];
        final isIncoming = movement.type == InventoryMovement.TYPE_IN;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIncoming ? Colors.green : Colors.red,
              child: Icon(
                isIncoming ? Icons.add : Icons.remove,
                color: Colors.white,
              ),
            ),
            title: Text(movement.productName),
            subtitle: Text(
              '${DateFormat('dd MMM yyyy').format(movement.date)} | ${movement.referenceType ?? 'Manual Adjustment'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isIncoming ? '+' : '-'}${movement.quantity.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIncoming ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                if (movement.unitPrice != null)
                  Text(
                    Formatters.formatCurrency(movement.unitPrice!),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            onTap: () {
              // Show movement details
            },
          ),
        );
      },
    );
  }

  Color _getStockStatusColor(String status) {
    switch (status) {
      case 'Out of Stock':
        return Colors.red;
      case 'Low Stock':
        return Colors.orange;
      case 'In Stock':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}