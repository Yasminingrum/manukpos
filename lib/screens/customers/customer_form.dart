import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../services/database_service.dart';
import '../../utils/validators.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({super.key, this.customer});

  @override
  _CustomerFormScreenState createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _isNew = true;
  DateTime? _selectedDate;

  // Form controllers
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();
  final TextEditingController _currentBalanceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _customerType = 'regular';
  bool _isActive = true;
  
  final List<String> _customerTypes = [
    'regular',
    'wholesale',
    'retail',
    'distributor',
    'vip'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _isNew = false;
      _initializeFormWithCustomer(widget.customer!);
    } else {
      // Set defaults for new customer
      _creditLimitController.text = '0.0';
      _currentBalanceController.text = '0.0';
    }
  }

  void _initializeFormWithCustomer(Customer customer) {
    // Handle all the non-null properties
    _codeController.text = customer.code ?? '';
    _nameController.text = customer.name;
    _phoneController.text = customer.phone ?? '';
    _emailController.text = customer.email ?? '';
    _addressController.text = customer.address ?? '';
    _cityController.text = customer.city ?? '';
    _postalCodeController.text = customer.postalCode ?? '';
    
    // Handle birthdate specifically
    var birthdate = customer.birthdate;
    if (birthdate != null && birthdate.isNotEmpty) {
      _selectedDate = DateTime.parse(birthdate);
      _birthdateController.text = birthdate;
    }
    
    _taxIdController.text = customer.taxId ?? '';
    
    // Handle numeric values with null checks
    var creditLimit = customer.creditLimit;
    _creditLimitController.text = creditLimit != null ? creditLimit.toString() : '0.0';
    
    var currentBalance = customer.currentBalance;
    _currentBalanceController.text = currentBalance != null ? currentBalance.toString() : '0.0';
    
    _notesController.text = customer.notes ?? '';
    _customerType = customer.customerType ?? 'regular';
    _isActive = customer.isActive == 1;
  }

  Future<void> _selectDate(BuildContext context) async {
    var picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert string values to appropriate types
      var creditLimit = 0.0;
      if (_creditLimitController.text.isNotEmpty) {
        creditLimit = double.parse(_creditLimitController.text);
      }
      
      var currentBalance = 0.0;
      if (_currentBalanceController.text.isNotEmpty) {
        currentBalance = double.parse(_currentBalanceController.text);
      }
      
      // Create a map with proper field names matching the database
      var customerData = {
        'id': widget.customer != null ? widget.customer!.id : 0,
        'code': _codeController.text.isNotEmpty ? _codeController.text : null,
        'name': _nameController.text,
        'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'email': _emailController.text.isNotEmpty ? _emailController.text : null,
        'address': _addressController.text.isNotEmpty ? _addressController.text : null,
        'city': _cityController.text.isNotEmpty ? _cityController.text : null,
        'postal_code': _postalCodeController.text.isNotEmpty ? _postalCodeController.text : null,
        'birthdate': _birthdateController.text.isNotEmpty ? _birthdateController.text : null,
        'join_date': widget.customer != null && widget.customer!.joinDate != null 
            ? widget.customer!.joinDate 
            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'customer_type': _customerType,
        'credit_limit': creditLimit,
        'current_balance': currentBalance,
        'tax_id': _taxIdController.text.isNotEmpty ? _taxIdController.text : null,
        'is_active': _isActive ? 1 : 0,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      if (_isNew) {
        // Using insert method based on your database implementation
        await _databaseService.insert('customers', customerData);
      } else {
        // Using update method based on your database implementation
        await _databaseService.update(
          'customers', 
          customerData,
          'id = ?',
          [customerData['id']]
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
      _showErrorDialog('Failed to save customer: $e');
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
        title: Text(_isNew ? 'Add Customer' : 'Edit Customer'),
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
                        labelText: 'Customer Code',
                        helperText: 'Optional - Leave blank for auto-generated code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
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
                    DropdownButtonFormField<String>(
                      value: _customerType,
                      decoration: const InputDecoration(
                        labelText: 'Customer Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _customerTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type[0].toUpperCase() + type.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value != null) {
                            _customerType = value;
                          }
                        });
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
                        const Text('Active Customer'),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _birthdateController,
                      decoration: InputDecoration(
                        labelText: 'Birthdate',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taxIdController,
                      decoration: const InputDecoration(
                        labelText: 'Tax ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Financial Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _creditLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Credit Limit',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          try {
                            double.parse(value);
                          } catch (e) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentBalanceController,
                      decoration: const InputDecoration(
                        labelText: 'Current Balance',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          try {
                            double.parse(value);
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
          child: Text(_isNew ? 'Add Customer' : 'Update Customer'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _birthdateController.dispose();
    _taxIdController.dispose();
    _creditLimitController.dispose();
    _currentBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}