import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../widgets/confirmation_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Fetch users from local database
      final users = await _databaseService.getUsers();
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: ${e.toString()}')),
      );
    }
  }

  void _navigateToUserForm({User? user}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(user: user),
      ),
    );
    
    if (result == true) {
      _loadUsers(); // Reload the users list
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      // Create a new user object with toggled active status
      final updatedUser = User(
        id: user.id,
        username: user.username,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        branchId: user.branchId,
        isActive: user.isActive == 1 ? 0 : 1,
      );
      
      // Update in database
      await _databaseService.updateUser(updatedUser);
      
      // Reload users
      _loadUsers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user.isActive == 1
                ? 'User ${user.name} deactivated'
                : 'User ${user.name} activated',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user status: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete User',
        content: 'Are you sure you want to delete ${user.name}? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: Colors.red,
      ),
    );
    
    if (confirm == true) {
      try {
        await _databaseService.deleteUser(user.id!);
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${user.name} deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: ${e.toString()}')),
        );
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'kasir':
        return 'Cashier';
      case 'manajer':
        return 'Manager';
      case 'owner':
        return 'Owner';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToUserForm(),
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Text(
                    'No users found.\nTap + to add a new user.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(user.name[0].toUpperCase()),
                        ),
                        title: Text(user.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.username),
                            Text(_getRoleDisplayName(user.role)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Active/Inactive toggle
                            IconButton(
                              icon: Icon(
                                user.isActive == 1
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                color: user.isActive == 1
                                    ? Colors.green
                                    : Colors.grey,
                                size: 30,
                              ),
                              onPressed: () => _toggleUserStatus(user),
                              tooltip: user.isActive == 1
                                  ? 'Deactivate'
                                  : 'Activate',
                            ),
                            // Edit button
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _navigateToUserForm(user: user),
                              tooltip: 'Edit',
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteUser(user),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () => _navigateToUserForm(user: user),
                      ),
                    );
                  },
                ),
    );
  }
}

// User Form for adding/editing users
class UserFormScreen extends StatefulWidget {
  final User? user;
  
  const UserFormScreen({super.key, this.user});

  @override
  _UserFormScreenState createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  
  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String _selectedRole = 'kasir'; // Default role
  int? _selectedBranchId;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isEditMode = false;
  List<Map<String, dynamic>> _branches = [];
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.user != null;
    
    if (_isEditMode) {
      // Populate form with user data
      _usernameController.text = widget.user!.username;
      _nameController.text = widget.user!.name;
      _emailController.text = widget.user!.email ?? '';
      _phoneController.text = widget.user!.phone ?? '';
      _selectedRole = widget.user!.role;
      _selectedBranchId = widget.user!.branchId;
      _isActive = widget.user!.isActive == 1;
    }
    
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await _databaseService.getBranches();
      setState(() {
        _branches = branches;
        // Set default branch if not in edit mode and branches exist
        if (!_isEditMode && branches.isNotEmpty && _selectedBranchId == null) {
          _selectedBranchId = branches[0]['id'] as int;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading branches: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = User(
        id: _isEditMode ? widget.user!.id : null,
        username: _usernameController.text,
        name: _nameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        role: _selectedRole,
        branchId: _selectedBranchId,
        isActive: _isActive ? 1 : 0,
        // For the password, only include it if it's provided in a new user or changed for existing user
        password: _passwordController.text.isEmpty && _isEditMode
            ? null  // Keep existing password
            : _passwordController.text,
      );
      
      if (_isEditMode) {
        await _databaseService.updateUser(user);
      } else {
        await _databaseService.createUser(user);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Return to previous screen with success flag
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving user: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit User' : 'Add User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveUser,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
                enabled: !_isEditMode, // Can't change username in edit mode
              ),
              const SizedBox(height: 16),
              
              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _isEditMode ? 'New Password (leave blank to keep current)' : 'Password',
                  hintText: _isEditMode ? 'Enter new password or leave blank' : 'Enter password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (!_isEditMode && (value == null || value.isEmpty)) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter full name',
                  prefixIcon: Icon(Icons.badge),
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
              
              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Simple email validation
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              // Role
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'admin', child: Text(_getRoleDisplayName('admin'))),
                  DropdownMenuItem(value: 'kasir', child: Text(_getRoleDisplayName('kasir'))),
                  DropdownMenuItem(value: 'manajer', child: Text(_getRoleDisplayName('manajer'))),
                  DropdownMenuItem(value: 'owner', child: Text(_getRoleDisplayName('owner'))),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Branch
              if (_branches.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _selectedBranchId,
                  decoration: const InputDecoration(
                    labelText: 'Branch',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                  items: _branches.map((branch) {
                    return DropdownMenuItem(
                      value: branch['id'] as int,
                      child: Text(branch['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBranchId = value;
                    });
                  },
                )
              else
                const Text('No branches available. Please create a branch first.'),
              const SizedBox(height: 16),
              
              // Active Status
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                secondary: Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(_isEditMode ? 'Update User' : 'Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'kasir':
        return 'Cashier';
      case 'manajer':
        return 'Manager';
      case 'owner':
        return 'Owner';
      default:
        return role;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}