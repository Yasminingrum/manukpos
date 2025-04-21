// widgets/customer_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/customer.dart';
import '../services/database_service.dart';
import 'custom_text_field.dart';

class CustomerSelector extends StatefulWidget {
  const CustomerSelector({super.key});

  @override
  State<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<CustomerSelector> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _searchQuery = '';
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      // Query customers
      final results = await databaseService.query(
        AppConstants.tableCustomers,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'name',
      );
      
      final customers = results.map((map) => Customer.fromMap(map)).toList();
      
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading customers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final name = customer.name.toLowerCase();
          final phone = customer.phone?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return name.contains(searchLower) || phone.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Pelanggan',
                style: TextStyle(
                  fontSize: 20,
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
          
          // Search field
          CustomTextField(
            controller: _searchController,
            labelText: 'Cari pelanggan',
            hintText: 'Nama atau nomor telepon',
            prefixIcon: const Icon(Icons.search),
            onChanged: _filterCustomers,
          ),
          
          const SizedBox(height: 16),
          
          // Add "General Customer" option
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
            title: const Text('Umum'),
            subtitle: const Text('Pelanggan tanpa data'),
            onTap: () => Navigator.pop(context, null),
          ),
          
          const Divider(),
          
          // Customers list
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredCustomers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchQuery.isEmpty
                          ? 'Belum ada pelanggan'
                          : 'Tidak ada pelanggan dengan kata kunci "$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LimitedBox(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = _filteredCustomers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(customer.name),
                    subtitle: customer.phone != null && customer.phone!.isNotEmpty
                        ? Text(customer.phone!)
                        : null,
                    onTap: () => Navigator.pop(context, customer),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}