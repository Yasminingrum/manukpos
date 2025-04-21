// product_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/category.dart';
import '../../services/database_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProductFormScreen extends StatefulWidget {
  final bool isEditing;
  final int? productId;

  const ProductFormScreen({
    super.key,
    required this.isEditing,
    this.productId,
  });

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  File? _imageFile;
  String? _imageUrl;
  List<Category> _categories = [];
  
  // Form fields
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int? _selectedCategoryId;
  final TextEditingController _buyingPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _discountPriceController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  bool _isService = false;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _allowFractions = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.isEditing && widget.productId != null) {
      _loadProduct(widget.productId!);
    } else {
      // Set defaults for new product
      _minStockController.text = '1';
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _discountPriceController.dispose();
    _minStockController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _tagsController.dispose();
    super.dispose();
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

  Future<void> _loadProduct(int productId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use query method instead of getProductById which isn't defined
      final productMaps = await _databaseService.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      
      if (productMaps.isEmpty) {
        throw Exception('Product not found');
      }
      
      final productMap = productMaps.first;
      
      _skuController.text = productMap['sku'];
      _barcodeController.text = productMap['barcode'] ?? '';
      _nameController.text = productMap['name'];
      _descriptionController.text = productMap['description'] ?? '';
      _selectedCategoryId = productMap['category_id'];
      _buyingPriceController.text = productMap['buying_price'].toString();
      _sellingPriceController.text = productMap['selling_price'].toString();
      if (productMap['discount_price'] != null) {
        _discountPriceController.text = productMap['discount_price'].toString();
      }
      _minStockController.text = productMap['min_stock']?.toString() ?? '1';
      if (productMap['weight'] != null) {
        _weightController.text = productMap['weight'].toString();
      }
      if (productMap['dimension_length'] != null) {
        _lengthController.text = productMap['dimension_length'].toString();
      }
      if (productMap['dimension_width'] != null) {
        _widthController.text = productMap['dimension_width'].toString();
      }
      if (productMap['dimension_height'] != null) {
        _heightController.text = productMap['dimension_height'].toString();
      }
      if (productMap['tags'] != null) {
        _tagsController.text = productMap['tags'];
      }
      
      setState(() {
        _isService = productMap['is_service'] == 1;
        _isActive = productMap['is_active'] == 1;
        _isFeatured = productMap['is_featured'] == 1;
        _allowFractions = productMap['allow_fractions'] == 1;
        _imageUrl = productMap['image_url'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading product: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrl = null; // Clear existing image URL
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload image and get URL if image was picked
      String? imageUrl = _imageUrl;
      if (_imageFile != null) {
        // In a real app, this would upload to a server or cloud storage
        // For this example, we'll assume we're just keeping the local path
        imageUrl = _imageFile!.path;
      }

      final now = DateTime.now().toIso8601String();

      // Create a product map from form fields
      final productMap = {
        'sku': _skuController.text,
        'barcode': _barcodeController.text.isEmpty ? null : _barcodeController.text,
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'category_id': _selectedCategoryId,
        'buying_price': double.parse(_buyingPriceController.text),
        'selling_price': double.parse(_sellingPriceController.text),
        'discount_price': _discountPriceController.text.isEmpty 
            ? null 
            : double.parse(_discountPriceController.text),
        'min_stock': int.parse(_minStockController.text),
        'weight': _weightController.text.isEmpty ? null : double.parse(_weightController.text),
        'dimension_length': _lengthController.text.isEmpty ? null : double.parse(_lengthController.text),
        'dimension_width': _widthController.text.isEmpty ? null : double.parse(_widthController.text),
        'dimension_height': _heightController.text.isEmpty ? null : double.parse(_heightController.text),
        'is_service': _isService ? 1 : 0,
        'is_active': _isActive ? 1 : 0,
        'is_featured': _isFeatured ? 1 : 0,
        'allow_fractions': _allowFractions ? 1 : 0,
        'image_url': imageUrl,
        'tags': _tagsController.text.isEmpty ? null : _tagsController.text,
        'sync_status': 'pending',
      };

      // Save to database
      if (widget.isEditing) {
        productMap['updated_at'] = now;
        await _databaseService.update(
          'products',
          productMap,
          'id = ?',
          [widget.productId!],
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        productMap['created_at'] = now;
        productMap['updated_at'] = now;
        await _databaseService.insert('products', productMap);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
          Navigator.pop(context, true); // Return success
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error saving product: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : _imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: (_imageFile == null && _imageUrl == null)
                              ? const Icon(Icons.add_a_photo, size: 50)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter product name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _skuController,
                              decoration: const InputDecoration(
                                labelText: 'SKU *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter SKU';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                labelText: 'Barcode',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedCategoryId,
                              items: _categories.map((category) {
                                return DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 3,
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
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _buyingPriceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Buying Price *',
                                      prefixText: 'Rp ',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _sellingPriceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Selling Price *',
                                      prefixText: 'Rp ',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _discountPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Discount Price',
                                prefixText: 'Rp ',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Inventory Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _minStockController,
                                    decoration: const InputDecoration(
                                      labelText: 'Minimum Stock Level',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SwitchListTile(
                                    title: const Text('Allow Fractions'),
                                    subtitle: const Text('Sell in decimals'),
                                    value: _allowFractions,
                                    onChanged: (value) {
                                      setState(() {
                                        _allowFractions = value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Physical Attributes Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Physical Attributes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: 'Weight (g)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _lengthController,
                                    decoration: const InputDecoration(
                                      labelText: 'Length (cm)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _widthController,
                                    decoration: const InputDecoration(
                                      labelText: 'Width (cm)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heightController,
                                    decoration: const InputDecoration(
                                      labelText: 'Height (cm)',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Additional Options Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Options',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Is Service'),
                              subtitle: const Text('Product is a service, not a physical item'),
                              value: _isService,
                              onChanged: (value) {
                                setState(() {
                                  _isService = value;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                            SwitchListTile(
                              title: const Text('Active'),
                              subtitle: const Text('Product is available for sale'),
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                            SwitchListTile(
                              title: const Text('Featured'),
                              subtitle: const Text('Show in featured products'),
                              value: _isFeatured,
                              onChanged: (value) {
                                setState(() {
                                  _isFeatured = value;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _tagsController,
                              decoration: const InputDecoration(
                                labelText: 'Tags (comma separated)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: _isSubmitting
                            ? const CircularProgressIndicator()
                            : Text(
                                widget.isEditing ? 'Update Product' : 'Save Product',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}