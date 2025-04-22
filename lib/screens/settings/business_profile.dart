import 'package:flutter/material.dart';
import '../../models/business.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  _BusinessProfileScreenState createState() => _BusinessProfileScreenState();
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
      // Assuming this function fetches business data from the local database
      final business = await _databaseService.getBusinessProfile();
      
      setState(() {
        _business = business;
        if (business != null) {
          _nameController.text = business.name;
          _addressController.text = business.address ?? '';
          _phoneController.text = business.phone ?? '';
          _emailController.text = business.email ?? '';
          _taxIdController.text = business.taxId ?? '';
          _logoPath = business.logoPath;
        }
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
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
      final updatedBusiness = Business(
        id: _business?.id,
        name: _nameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        taxId: _taxIdController.text,
        logoPath: _logoPath,
      );
      
      // Save to database
      await _databaseService.saveBusinessProfile(updatedBusiness);
      
      setState(() {
        _business = updatedBusiness;
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile saved successfully')),
      );
    } catch (e) {
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
                      label: 'Business Name',
                      hint: 'Enter your business name',
                      prefixIcon: Icons.business,
                      validator: (value) => Validators.required(value, 'Business name is required'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Address
                    CustomTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter your business address',
                      prefixIcon: Icons.location_on,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      hint: 'Enter your business phone',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your business email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value != null && value.isNotEmpty
                          ? Validators.email(value)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Tax ID
                    CustomTextField(
                      controller: _taxIdController,
                      label: 'Tax ID / NPWP',
                      hint: 'Enter your tax ID number',
                      prefixIcon: Icons.receipt_long,
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