import 'package:flutter/material.dart';
import '../../models/business.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_text_field.dart';
// Removed unused import: '../../utils/validators.dart'

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  
  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  
  Business? _business;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Menggunakan query untuk mengambil business profile dari database
      final profiles = await _databaseService.query(
        'business_profile',
        limit: 1,
      );
      
      if (!mounted) return;
      
      setState(() {
        if (profiles.isNotEmpty) {
          _business = Business.fromMap(profiles.first);
          _nameController.text = _business!.name;
          _addressController.text = _business!.address ?? '';
          _phoneController.text = _business!.phone ?? '';
          _emailController.text = _business!.email ?? '';
          _taxIdController.text = _business!.taxId ?? '';
          _logoPath = _business!.logoPath;
        }
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading business profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveBusinessProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Changed from final to var since we need to modify it
      var updatedBusiness = Business(
        id: _business?.id,
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        taxId: _taxIdController.text,
        logoPath: _logoPath,
      );
      
      // Save to database using generic methods instead of specific function
      if (_business?.id != null) {
        // Update existing record
        await _databaseService.update(
          'business_profile',
          updatedBusiness.toMap(),
          'id = ?',
          [_business!.id],
        );
      } else {
        // Insert new record
        final id = await _databaseService.insert(
          'business_profile',
          updatedBusiness.toMap(),
        );
        updatedBusiness = Business(
          id: id,
          name: updatedBusiness.name,
          address: updatedBusiness.address,
          phone: updatedBusiness.phone,
          email: updatedBusiness.email,
          taxId: updatedBusiness.taxId,
          logoPath: updatedBusiness.logoPath,
        );
      }
      
      if (!mounted) return;
      
      setState(() {
        _business = updatedBusiness;
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving business profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickLogo() async {
    // Implement image picking functionality
    // This would typically use image_picker package
    // For now we'll just show a placeholder message
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo picking functionality to be implemented')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveBusinessProfile,
            tooltip: 'Save Profile',
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
                    // Logo section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickLogo,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                                image: _logoPath != null
                                    ? DecorationImage(
                                        image: AssetImage(_logoPath!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _logoPath == null
                                  ? const Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to change logo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Form fields
                    const Text(
                      'Business Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Business Name
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Business Name',
                      hintText: 'Enter your business name',
                      prefixIcon: const Icon(Icons.business),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Business name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Address
                    CustomTextField(
                      controller: _addressController,
                      labelText: 'Address',
                      hintText: 'Enter your business address',
                      prefixIcon: const Icon(Icons.location_on),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone',
                      hintText: 'Enter your business phone',
                      prefixIcon: const Icon(Icons.phone),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'Enter your business email',
                      prefixIcon: const Icon(Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          // Simple email validation
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Tax ID
                    CustomTextField(
                      controller: _taxIdController,
                      labelText: 'Tax ID / NPWP',
                      hintText: 'Enter your tax ID number',
                      prefixIcon: const Icon(Icons.receipt_long),
                    ),
                    const SizedBox(height: 24),
                    
                    // Receipt Customization Section
                    const Text(
                      'Receipt Customization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Add receipt customization options here
                    // For example, toggle switches for showing tax info, 
                    // receipt footer text field, etc.
                    
                    const SizedBox(height: 16),
                    
                    // Save button at bottom too for better UX
                    if (!_isSaving)
                      ElevatedButton(
                        onPressed: _saveBusinessProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Save Changes'),
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }
}