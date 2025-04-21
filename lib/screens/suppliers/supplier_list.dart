import 'package:flutter/material.dart';
import '../../models/supplier.dart';
import '../../services/database_service.dart';
import 'supplier_detail.dart';
import 'supplier_form.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the query method from DatabaseService to get all suppliers
      final List<Map<String, dynamic>> suppliersData = await _databaseService.query(
        'suppliers',
        orderBy: 'name ASC',
      );
      
      // Convert the raw data to Supplier objects
      final List<Supplier> suppliers = suppliersData.map((data) => Supplier.fromMap(data)).toList();
      
      setState(() {
        _suppliers = suppliers;
        _filteredSuppliers = suppliers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load suppliers: $e');
    }
  }

  void _filterSuppliers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSuppliers = _suppliers;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredSuppliers = _suppliers.where((supplier) {
        return supplier.name.toLowerCase().contains(lowercaseQuery) ||
            (supplier.code?.toLowerCase().contains(lowercaseQuery) ?? false) ||
            (supplier.phone?.toLowerCase().contains(lowercaseQuery) ?? false) ||
            (supplier.email?.toLowerCase().contains(lowercaseQuery) ?? false) ||
            (supplier.contactPerson?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuppliers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Suppliers',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterSuppliers('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: _filterSuppliers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSuppliers.isEmpty
                    ? const Center(child: Text('No suppliers found'))
                    : ListView.builder(
                        itemCount: _filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = _filteredSuppliers[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  supplier.name.isNotEmpty
                                      ? supplier.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(supplier.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(supplier.contactPerson ?? 'No contact person'),
                                  Text(supplier.phone ?? 'No phone'),
                                ],
                              ),
                              trailing: Icon(
                                supplier.isActive == 1
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: supplier.isActive == 1
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SupplierDetailScreen(supplier: supplier),
                                  ),
                                );
                                if (result == true) {
                                  _loadSuppliers();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SupplierFormScreen(),
            ),
          );
          if (result == true) {
            _loadSuppliers();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}