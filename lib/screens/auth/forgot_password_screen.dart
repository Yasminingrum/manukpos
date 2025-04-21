import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../config/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _requestSent = false;
  
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
      apiService: ApiService(baseUrl: 'https://documenter.getpostman.com/view/37267696/2sB2ca8L6X'),
      sharedPreferences: sharedPreferences,
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Karena requestPasswordReset tidak terdefinisi di AuthService,
        // kita akan menggunakan API langsung untuk sementara
        final result = await _authService.apiService.post(
          '/auth/password/reset-request',
          {'email': _emailController.text},
        );
        
        if (!mounted) return;
        
        final success = result['success'] == true;
        
        if (success) {
          setState(() {
            _requestSent = true;
          });
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to send reset password request. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                        height: 80,
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      const Text(
                        'Lupa Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      if (!_requestSent) ...[
                        // Description
                        const Text(
                          'Masukkan email akun Anda untuk menerima instruksi pengaturan ulang password.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        
                        // Form
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
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.validateEmail,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _resetPassword(),
                                ),
                                const SizedBox(height: 24),
                                
                                // Submit Button
                                CustomButton(
                                  text: 'Kirim Instruksi Reset',
                                  onPressed: _resetPassword,
                                  variant: ButtonVariant.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Success message
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
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 80,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Permintaan Reset Password Terkirim!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Instruksi pengaturan ulang password telah dikirim ke ${_emailController.text}',
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Silakan periksa email Anda dan ikuti petunjuk untuk mengatur ulang password.',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              
                              // Back to Login Button
                              CustomButton(
                                text: 'Kembali ke Halaman Login',
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                variant: ButtonVariant.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Back to Login Link
                      if (!_requestSent)
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Kembali ke Halaman Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}