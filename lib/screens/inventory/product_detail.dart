// product_detail.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../models/product.dart';
import '../../models/inventory.dart';
import '../../services/database_service.dart';
import '../../services/product_service.dart'; 
import '../../services/api_service.dart';
import '../../widgets/loading_overlay.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late final ProductService _productService;
  late TabController _tabController;
  final Logger _logger = Logger();
  
  bool _isLoading = true;
  Product? _product;
  List<InventoryItem> _inventoryItems = [];
  
  @override
  void initState() {
    super.initState();
    
    final apiService = ApiService(baseUrl: 'https://documenter.getpostman.com/view/37267696/2sB2ca8L6X');
    
    _productService = ProductService(
      apiService: apiService,
      databaseService: _databaseService,
    );
    
    _tabController = TabController(length: 2, vsync: this);
    _loadProductData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use the productService to get the product by ID
      final product = await _productService.getProductById(widget.productId);
      
      // Get inventory items through database query
      final List<Map<String, dynamic>> inventoryMaps = await _databaseService.query(
        'inventory',
        where: 'product_id = ?',
        whereArgs: [widget.productId],
      );
      
      final List<InventoryItem> inventoryItems = [];
      
      // Convert maps to InventoryItem objects
      for (var map in inventoryMaps) {
        try {
          // Get branch name for display
          final branchMaps = await _databaseService.query(
            'branches',
            columns: ['name'],
            where: 'id = ?',
            whereArgs: [map['branch_id']],
            limit: 1,
          );
          
          String branchName = 'Unknown Branch';
          if (branchMaps.isNotEmpty) {
            branchName = branchMaps.first['name'] as String;
          }
          
          // Add branch name to the map before converting
          map['branch_name'] = branchName;
          
          inventoryItems.add(InventoryItem.fromJson(map));
        } catch (e) {
          _logger.e('Error converting inventory item: $e');
        }
      }
      
      setState(() {
        _product = product;
        _inventoryItems = inventoryItems;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading product data: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading product data: $e');
    }
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
  
  Widget _buildDetailItem(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : null,
                color: isHighlighted ? Theme.of(context).primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    if (_product == null) {
      return const Center(
        child: Text('Product not found'),
      );
    }
    
    // Determine if the product has a discount
    final hasDiscount = _product!.discountPrice != null && 
                        _product!.discountPrice! < _product!.sellingPrice;
                        
    // Calculate discount percentage if applicable
    String? discountPercentage;
    if (hasDiscount) {
      final discount = _product!.sellingPrice - _product!.discountPrice!;
      final percentage = (discount / _product!.sellingPrice) * 100;
      discountPercentage = percentage.toStringAsFixed(1);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          if (_product!.imageUrl != null)
            Center(
              child: Container(
                width: 200,
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_product!.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          
          // Basic Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildDetailItem('Product Name:', _product!.name, isHighlighted: true),
                  _buildDetailItem('SKU:', _product!.sku),
                  if (_product!.barcode != null)
                    _buildDetailItem('Barcode:', _product!.barcode!),
                  _buildDetailItem('Category:', _product!.category),
                  if (_product!.description != null && _product!.description!.isNotEmpty)
                    _buildDetailItem('Description:', _product!.description!),
                  
                  // Status indicators
                  Wrap(
                    spacing: 8,
                    children: [
                      if (!_product!.isActive)
                        Chip(
                          label: const Text('INACTIVE'),
                          backgroundColor: Colors.grey,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      if (_product!.isService)
                        Chip(
                          label: const Text('SERVICE'),
                          backgroundColor: Colors.blue,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      if (_product!.isFeatured)
                        Chip(
                          label: const Text('FEATURED'),
                          backgroundColor: Colors.orange,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      if (_product!.allowFractions)
                        Chip(
                          label: const Text('FRACTIONAL'),
                          backgroundColor: Colors.purple,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Pricing Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildDetailItem('Buying Price:', 'Rp ${_product!.buyingPrice.toStringAsFixed(0)}'),
                  _buildDetailItem(
                    'Selling Price:', 
                    'Rp ${_product!.sellingPrice.toStringAsFixed(0)}',
                    isHighlighted: !hasDiscount,
                  ),
                  if (hasDiscount) ...[
                    _buildDetailItem(
                      'Discount Price:', 
                      'Rp ${_product!.discountPrice!.toStringAsFixed(0)} ($discountPercentage% off)',
                      isHighlighted: true,
                    ),
                    _buildDetailItem(
                      'Profit Margin:', 
                      _calculateProfitMargin(_product!.discountPrice!, _product!.buyingPrice),
                    ),
                  ] else
                    _buildDetailItem(
                      'Profit Margin:', 
                      _calculateProfitMargin(_product!.sellingPrice, _product!.buyingPrice),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Inventory Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildDetailItem('Minimum Stock:', _product!.minStock.toString()),
                  if (!_product!.isService) ...[
                    if (_product!.weight != null)
                      _buildDetailItem('Weight:', '${_product!.weight} g'),
                    if (_product!.dimensionLength != null && 
                        _product!.dimensionWidth != null && 
                        _product!.dimensionHeight != null)
                      _buildDetailItem(
                        'Dimensions:', 
                        '${_product!.dimensionLength} × ${_product!.dimensionWidth} × ${_product!.dimensionHeight} cm',
                      ),
                  ],
                  if (_product!.tags != null && _product!.tags!.isNotEmpty)
                    _buildDetailItem('Tags:', _product!.tags!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _calculateProfitMargin(double sellingPrice, double buyingPrice) {
    if (buyingPrice == 0) {
      return '∞';
    }
    
    final profit = sellingPrice - buyingPrice;
    final margin = (profit / buyingPrice) * 100;
    
    return '${margin.toStringAsFixed(1)}%';
  }
  
  Widget _buildInventoryTab() {
    if (_inventoryItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No inventory records found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Fix the argument order in this ElevatedButton.icon
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to add inventory screen
                // This would be implemented in a real app
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Inventory'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inventoryItems.length,
      itemBuilder: (context, index) {
        final item = _inventoryItems[index];
        final isLowStock = item.isLowStock;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.branchName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LOW STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(),
                _buildDetailItem('Stock Quantity:', item.quantity.toString()),
                _buildDetailItem('Reserved:', item.reservedQuantity.toString()),
                _buildDetailItem(
                  'Available:', 
                  item.availableQuantity.toString(),
                  isHighlighted: true,
                ),
                _buildDetailItem('Min Stock Level:', item.minStockLevel.toString()),
                if (item.maxStockLevel != null)
                  _buildDetailItem('Max Stock Level:', item.maxStockLevel.toString()),
                if (item.reorderPoint != null)
                  _buildDetailItem('Reorder Point:', item.reorderPoint.toString()),
                if (item.shelfLocation != null && item.shelfLocation!.isNotEmpty)
                  _buildDetailItem('Shelf Location:', item.shelfLocation!),
                if (item.lastStockUpdate != null)
                  _buildDetailItem(
                    'Last Updated:', 
                    _formatDate(item.lastStockUpdate!),
                  ),
                
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Fix argument order for these buttons
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to adjust stock screen
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Adjust Stock'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to stock history screen
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('History'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Product Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/product/edit',
                arguments: widget.productId,
              );
              
              if (result == true) {
                _loadProductData();
              }
            },
            tooltip: 'Edit Product',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProductData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'DETAILS', icon: Icon(Icons.info_outline)),
            Tab(text: 'INVENTORY', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildInventoryTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show quick action menu
          _showQuickActions();
        },
        tooltip: 'Quick Actions',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showQuickActions() {
    if (_product == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Quick Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart),
              title: const Text('Purchase Stock'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to purchase screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Transfer Stock'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to transfer screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Generate Barcode'),
              onTap: () {
                Navigator.pop(context);
                // Generate barcode
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print Label'),
              onTap: () {
                Navigator.pop(context);
                // Print label
              },
            ),
          ],
        ),
      ),
    );
  }
}