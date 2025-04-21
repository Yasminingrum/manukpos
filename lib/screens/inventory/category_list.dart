// category_list.dart
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/database_service.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  _CategoryListScreenState createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Category> _categories = [];
  bool _isLoading = true;
  
  // For editing and creating categories
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _databaseService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error loading categories: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _refreshCategories() async {
    await _loadCategories();
  }

  void _showAddEditCategoryDialog({Category? category}) {
    // Reset form values
    _nameController.text = category?.name ?? '';
    _codeController.text = category?.code ?? '';
    _descriptionController.text = category?.description ?? '';
    _selectedParentId = category?.parentId;
    
    final bool isEditing = category != null;
    final parentCategories = _categories
        .where((c) => c.id != category?.id) // Cannot be parent of itself
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter category name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Category Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: 'Parent Category',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedParentId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None (Top Level)'),
                    ),
                    ...parentCategories.map((category) {
                      return DropdownMenuItem<int?>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedParentId = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => _saveCategory(isEditing ? category.id : null),
            child: Text(isEditing ? 'UPDATE' : 'SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory(int? categoryId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Determine level and path
      int level = 1;
      String path = '';
      
      if (_selectedParentId != null) {
        final parentCategory = _categories.firstWhere((c) => c.id == _selectedParentId);
        level = parentCategory.level + 1;
        path = parentCategory.path != null && parentCategory.path!.isNotEmpty
            ? '${parentCategory.path}/${parentCategory.id}'
            : '${parentCategory.id}';
      }

      final category = Category(
        id: categoryId ?? 0, // 0 for new categories
        name: _nameController.text,
        code: _codeController.text.isEmpty ? null : _codeController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        parentId: _selectedParentId,
        level: level,
        path: path,
      );

      if (categoryId == null) {
        // Create new category
        await _databaseService.insertCategory(category);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category added successfully')),
          );
        }
      } else {
        // Update existing category
        await _databaseService.updateCategory(category);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category updated successfully')),
          );
        }
      }

      // Refresh the list
      await _refreshCategories();
    } catch (e) {
      _showErrorSnackBar('Error saving category: $e');
    }
  }

  Future<void> _deleteCategory(Category category) async {
    // Check if the category has children
    final hasChildren = _categories.any((c) => c.parentId == category.id);
    
    if (hasChildren) {
      _showErrorSnackBar('Cannot delete: This category has subcategories');
      return;
    }
    
    // Check if the category has products
    final hasProducts = await _databaseService.categoryHasProducts(category.id);
    
    if (hasProducts) {
      _showErrorSnackBar('Cannot delete: This category has products');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete category "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseService.deleteCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted successfully')),
          );
          await _refreshCategories();
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error deleting category: $e');
        }
      }
    }
  }

  Widget _buildCategoryItem(Category category) {
    final hasChildren = _categories.any((c) => c.parentId == category.id);
    final childCategories = _categories.where((c) => c.parentId == category.id).toList();
    
    return Column(
      children: [
        ListTile(
          leading: Icon(
            hasChildren ? Icons.folder : Icons.folder_open,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            category.name,
            style: TextStyle(
              fontWeight: category.parentId == null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            category.code ?? 'No Code',
            style: TextStyle(
              color: category.code == null ? Colors.grey : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showAddEditCategoryDialog(category: category),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteCategory(category),
              ),
            ],
          ),
        ),
        if (hasChildren)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: childCategories.map(_buildCategoryItem).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get only top-level categories
    final topLevelCategories = _categories.where((c) => c.parentId == null).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshCategories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : topLevelCategories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No categories found'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditCategoryDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Category'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshCategories,
                  child: ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: topLevelCategories.map(_buildCategoryItem).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditCategoryDialog(),
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }
}