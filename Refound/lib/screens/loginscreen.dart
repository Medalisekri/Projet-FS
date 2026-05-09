import 'package:flutter/material.dart';
import 'package:refound/theme/apptheme.dart';
import 'package:refound/widgets/header.dart';
import 'package:refound/widgets/labeledfeild.dart';
import '../services/authservice.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  bool _obscure = true, _loading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

 
  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_reset_outlined,
                    size: 48, color: AppColors.teal),
                const SizedBox(height: 16),
                const Text('Reset Password',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                  'Enter your email and we\'ll send you a reset link.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                  
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => loading = true);

                      try {
                        await _authService.sendPasswordReset(
                            email: emailCtrl.text.trim());

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Reset link sent to ${emailCtrl.text.trim()}'),
                              backgroundColor: AppColors.teal,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => loading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              child: loading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Send Link'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = await _authService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (mounted && user != null) {
        if (user.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admindash');
        } else {
          Navigator.pushReplacementNamed(context, '/userdash');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeroHeader(
            height: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset('lib/assets/logo.png',
                          fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('ReFound',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Text('Find your lost items in Tunisia',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back 👋',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Sign in to continue',
                          style: TextStyle(
                              color:
                                  AppColors.textSecondary.withOpacity(0.7),
                              fontSize: 13)),
                      const SizedBox(height: 28),

                      LabeledField(
                        prefixIcon: const Icon(Icons.mail_outlined, size: 20),
                        label: 'Email',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      LabeledField(
                        prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                        label: 'Password',
                        controller: _passCtrl,
                        obscureText: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < 7) return 'Min 7 characters';
                          return null;
                        },
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          // ✅ Now correctly calls the method
                          onPressed: _showForgotPassword,
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.teal),
                          child: const Text('Forgot Password?',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(height: 8),

                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                      
                        
                        child: _loading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 20),

                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/signup'),
                              child: const Text('Sign Up',
                                  style: TextStyle(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ]),
                    ],
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