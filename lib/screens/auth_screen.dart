import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showError(String msg) => setState(() => _error = msg);

  Future<void> _login() async {
    if (_loginEmail.text.isEmpty || _loginPass.text.isEmpty) {
      return _showError('Please fill all fields');
    }
    final auth = context.read<AuthProvider>();
    final err = await auth.loginUser(_loginEmail.text.trim(), _loginPass.text.trim());
    if (err != null && mounted) _showError(err);
  }

  Future<void> _register() async {
    if (_regName.text.isEmpty || _regEmail.text.isEmpty || _regPass.text.isEmpty) {
      return _showError('Please fill all fields');
    }
    final auth = context.read<AuthProvider>();
    final err = await auth.registerUser({
      'name': _regName.text.trim(),
      'email': _regEmail.text.trim(),
      'password': _regPass.text.trim(),
    });
    if (err != null && mounted) _showError(err);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF4f46e5)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF7c3aed).withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                const Text('TrustVault', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                const Text('Secure Document Wallet', style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
                const SizedBox(height: 36),

                // Card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0f0f1f),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1e293b)),
                  ),
                  child: Column(
                    children: [
                      // Tab bar
                      Container(
                        margin: const EdgeInsets.all(8),
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a2e),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF6d28d9)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF64748b),
                          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                          tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
                        ),
                      ),

                      // Tab views
                      SizedBox(
                        height: 280,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Login
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                              child: Column(
                                children: [
                                  _field(_loginEmail, 'Email', Icons.email_outlined),
                                  const SizedBox(height: 12),
                                  _field(_loginPass, 'Password', Icons.lock_outline, obscure: _obscure, onToggle: () => setState(() => _obscure = !_obscure)),
                                  if (_error != null) ...[
                                    const SizedBox(height: 10),
                                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
                                      child: Row(children: [const Icon(Icons.error_outline, color: Colors.red, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)))]),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  _btn(auth.loading ? null : _login, auth.loading ? 'Logging in...' : 'Login'),
                                ],
                              ),
                            ),
                            // Register
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                              child: Column(
                                children: [
                                  _field(_regName, 'Full Name', Icons.person_outline),
                                  const SizedBox(height: 10),
                                  _field(_regEmail, 'Email', Icons.email_outlined),
                                  const SizedBox(height: 10),
                                  _field(_regPass, 'Password', Icons.lock_outline, obscure: _obscure, onToggle: () => setState(() => _obscure = !_obscure)),
                                  if (_error != null) ...[
                                    const SizedBox(height: 8),
                                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
                                      child: Row(children: [const Icon(Icons.error_outline, color: Colors.red, size: 16), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)))]),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  _btn(auth.loading ? null : _register, auth.loading ? 'Creating account...' : 'Create Account'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon, {bool obscure = false, VoidCallback? onToggle}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF475569)),
        prefixIcon: Icon(icon, color: const Color(0xFF475569), size: 20),
        suffixIcon: onToggle != null ? IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF475569), size: 20), onPressed: onToggle) : null,
        filled: true,
        fillColor: const Color(0xFF1a1a2e),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1e293b))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1e293b))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7c3aed))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _btn(VoidCallback? onPressed, String label) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: onPressed != null ? const LinearGradient(colors: [Color(0xFF7c3aed), Color(0xFF6d28d9)]) : null,
            color: onPressed == null ? const Color(0xFF1e293b) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}
