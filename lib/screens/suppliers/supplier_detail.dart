import 'package:flutter/material.dart';
import '../../models/supplier.dart';
import '../../models/product.dart';
import '../../services/database_service.dart';
import 'supplier_form.dart';

class SupplierDetailScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierDetailScreen({
    super.key,
    required this.supplier,
  });

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  List<Product> _products = [];
  Supplier? _refreshedSupplier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshSupplierData();
    _loadSupplierProducts();
  }

  Future<void> _refreshSupplierData() async {
    try {
      // Query the suppliers table to get the latest data
      final List<Map<String, dynamic>> supplierData = await _databaseService.query(
        'suppliers',
        where: 'id = ?',
        whereArgs: [widget.supplier.id],
        limit: 1,
      );
      
      if (supplierData.isNotEmpty) {
        setState(() {
          _refreshedSupplier = Supplier.fromMap(supplierData.first);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to load supplier details: $e');
    }
  }

  Future<void> _loadSupplierProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get products through a join query
      final List<Map<String, dynamic>> productData = await _databaseService.rawQuery('''
        SELECT p.* FROM products p
        JOIN product_suppliers ps ON p.id = ps.product_id
        WHERE ps.supplier_id = ?
      ''', [widget.supplier.id]);
      
      setState(() {
        _products = productData.map((data) => Product.fromMap(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load products: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${widget.supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteSupplier();
    }
  }

  Future<void> _deleteSupplier() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete the supplier from the database
      await _databaseService.delete(
        'suppliers',
        'id = ?',
        [widget.supplier.id],
      );
      
      setState(() {
        _isLoading = false;
      });
      // Return to previous screen and trigger refresh
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to delete supplier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplier = _refreshedSupplier ?? widget.supplier;

    return Scaffold(
      appBar: AppBar(
        title: Text(supplier.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SupplierFormScreen(supplier: supplier),
                ),
              );
              if (result == true) {
                _refreshSupplierData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(supplier),
                _buildProductsTab(),
              ],
            ),
    );
  }

  Widget _buildDetailsTab(Supplier supplier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Supplier ID', supplier.code ?? 'Not Assigned'),
                  _buildInfoRow('Name', supplier.name),
                  _buildInfoRow('Contact Person', supplier.contactPerson ?? 'Not Available'),
                  _buildInfoRow('Phone', supplier.phone ?? 'Not Available'),
                  _buildInfoRow('Email', supplier.email ?? 'Not Available'),
                  _buildInfoRow('Status', supplier.isActive == 1 ? 'Active' : 'Inactive'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (supplier.address != null)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Address', supplier.address!),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Tax ID', supplier.taxId ?? 'Not Available'),
                  _buildInfoRow(
                    'Payment Terms',
                    supplier.paymentTerms != null
                        ? '${supplier.paymentTerms} days'
                        : 'Not Specified',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (supplier.notes != null && supplier.notes!.isNotEmpty)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(supplier.notes!),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return const Center(
        child: Text('No products found for this supplier'),
      );
    }

    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                    child: const Icon(Icons.inventory),
                  ),
            title: Text(product.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SKU: ${product.sku}'),
                Text('Buy Price: Rp ${product.buyingPrice.toStringAsFixed(2)}'),
              ],
            ),
            trailing: Text(
              'Sell: Rp ${product.sellingPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              // Navigate to product details
              // To be implemented
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