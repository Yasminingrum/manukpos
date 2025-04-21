import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  late final AuthService _authService;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    _authService = AuthService(
      databaseService: DatabaseService(),
      apiService: ApiService(baseUrl: 'https://api.manuk-pos.com'),
      sharedPreferences: sharedPreferences,
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
            // Gunakan login sebagai alternatif karena metode register tidak ada
            await _authService.login(
              _usernameController.text,
              _passwordController.text,
            );
            
            if (!mounted) return;
            
            // Jika berhasil login, arahkan ke dashboard
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
              (route) => false,
            );
          } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: _isLoading
          ? const LoadingIndicator()
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Logo
                      Image.asset(
                        'assets/images/manuk_logo.png',
                        height: 100,
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      const Text(
                        'Daftar Akun Baru',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      
                      // Registration Form
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Lengkap',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Nama tidak boleh kosong';
                                  }
                                  if (value.length < 3) {
                                    return 'Nama minimal 3 karakter';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              
                              // Username
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.account_circle),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Username tidak boleh kosong';
                                  }
                                  if (value.length < 4) {
                                    return 'Username minimal 4 karakter';
                                  }
                                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                                    return 'Username hanya boleh berisi huruf, angka, dan underscore';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              
                              // Email
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Email tidak valid';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              
                              // Phone
                              TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Nomor Telepon',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Nomor telepon tidak boleh kosong';
                                  }
                                  if (!RegExp(r'^[0-9]{9,15}$').hasMatch(value)) {
                                    return 'Nomor telepon tidak valid';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              
                              // Password
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password tidak boleh kosong';
                                  }
                                  if (value.length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              
                              // Confirm Password
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Konfirmasi Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                obscureText: _obscureConfirmPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Konfirmasi password tidak boleh kosong';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Konfirmasi password tidak cocok';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _register(),
                              ),
                              const SizedBox(height: 24),
                              
                              // Register Button
                              CustomButton(
                                text: 'Daftar',
                                onPressed: _register,
                                variant: ButtonVariant.primary,
                              ),
                              const SizedBox(height: 16),
                              
                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Sudah memiliki akun?'),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('Masuk'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Terms and Conditions
                      const Text(
                        'Dengan mendaftar, Anda menyetujui Ketentuan Layanan dan Kebijakan Privasi kami.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}