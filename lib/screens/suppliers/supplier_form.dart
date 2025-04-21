import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/supplier.dart';
import '../../services/database_service.dart';
import '../../utils/validators.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _isNew = true;

  // Form controllers
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _paymentTermsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _isNew = false;
      _initializeFormWithSupplier(widget.supplier!);
    } else {
      // Set defaults for new supplier
      _paymentTermsController.text = '0';
    }
  }

  void _initializeFormWithSupplier(Supplier supplier) {
    _codeController.text = supplier.code ?? '';
    _nameController.text = supplier.name;
    _contactPersonController.text = supplier.contactPerson ?? '';
    _phoneController.text = supplier.phone ?? '';
    _emailController.text = supplier.email ?? '';
    _addressController.text = supplier.address ?? '';
    _taxIdController.text = supplier.taxId ?? '';
    _paymentTermsController.text = (supplier.paymentTerms ?? 0).toString();
    _notesController.text = supplier.notes ?? '';
    _isActive = supplier.isActive == 1;
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supplier = Supplier(
        id: widget.supplier?.id ?? 0,
        code: _codeController.text.isNotEmpty ? _codeController.text : null,
        name: _nameController.text,
        contactPerson: _contactPersonController.text.isNotEmpty ? _contactPersonController.text : null,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        taxId: _taxIdController.text.isNotEmpty ? _taxIdController.text : null,
        paymentTerms: _paymentTermsController.text.isNotEmpty ? 
            int.parse(_paymentTermsController.text) : null,
        isActive: _isActive ? 1 : 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (_isNew) {
        // Insert new supplier
        await _databaseService.insert('suppliers', supplier.toMap());
      } else {
        // Update existing supplier
        await _databaseService.update(
          'suppliers',
          supplier.toMap(),
          'id = ?',
          [supplier.id],
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to save supplier: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add Supplier' : 'Edit Supplier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
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
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Code',
                        helperText: 'Optional - Leave blank for auto-generated code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPersonController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Person',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          return Validators.validateEmail(value);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),
                        const Text('Active Supplier'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Address Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Payment Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taxIdController,
                      decoration: const InputDecoration(
                        labelText: 'Tax ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _paymentTermsController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Terms (days)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          try {
                            int.parse(value);
                          } catch (e) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _saveForm,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: Text(_isNew ? 'Add Supplier' : 'Update Supplier'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}