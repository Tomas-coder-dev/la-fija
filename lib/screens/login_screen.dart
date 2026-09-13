import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/ui/custom_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor ingresa correo y contraseña');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      _showError('Error al iniciar sesión: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor ingresa correo y contraseña');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      _showError('Error al registrarse: ${e.message}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    CustomToast.show(context, message, isError: true);
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.indigo.shade200, size: 22),
      suffixIcon: suffixIcon,
      labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.indigo.shade400, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Fondo oscuro premium
          Container(
            color: const Color(0xFF070710),
          ),
          
          // Efecto de luz superior
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo.shade800.withOpacity(0.6),
                gradient: RadialGradient(
                  colors: [
                    Colors.indigo.shade600.withOpacity(0.8),
                    Colors.transparent,
                  ]
                )
              ),
            ),
          ),
          
          // Efecto de luz inferior
          Positioned(
            bottom: -100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.shade900.withOpacity(0.4),
                gradient: RadialGradient(
                  colors: [
                    Colors.deepPurple.shade700.withOpacity(0.5),
                    Colors.transparent,
                  ]
                )
              ),
            ),
          ),
          
          // Blur general del fondo
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Logo Premium ──────────────────────────────
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade400,
                                Colors.indigo.shade700,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.shade500.withOpacity(0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                                offset: const Offset(0, 8)
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          'La Fija',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Control total de tus tarjetas.\nCero membresías sorpresa.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white60,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // ── Tarjeta de Formulario Glassmorphism ──────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                                    decoration: _inputDecoration('Correo electrónico', Icons.alternate_email_rounded),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                                    decoration: _inputDecoration(
                                      'Contraseña', 
                                      Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          color: Colors.white54,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      )
                                    ),
                                  ),
                                  const SizedBox(height: 36),
            
                                  // Botones
                                  if (_isLoading)
                                    const CircularProgressIndicator(color: Colors.indigoAccent)
                                  else
                                    Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: ElevatedButton(
                                            onPressed: _signIn,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigoAccent.shade400,
                                              foregroundColor: Colors.white,
                                              elevation: 8,
                                              shadowColor: Colors.indigoAccent.withOpacity(0.5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Text(
                                              'Iniciar Sesión',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: OutlinedButton(
                                            onPressed: _signUp,
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              backgroundColor: Colors.white.withOpacity(0.02),
                                            ),
                                            child: Text(
                                              'Crear Cuenta',
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

