import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/auth_provider.dart';
import '../../core/utils/app_routes.dart';
import '../../core/utils/network_error_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _hasShownStaleError = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  String _role = 'donor';
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  static List<Map<String, dynamic>> get roles => [
    {
      'value': 'donor',
      'label': 'Donor',
      'icon': Icons.favorite_rounded,
      'color': AppTheme.roleDonorAccent,
    },
    {
      'value': 'ngo',
      'label': 'NGO / Hospital',
      'icon': Icons.business_rounded,
      'color': AppTheme.roleNgoAccent,
    },
    {
      'value': 'volunteer',
      'label': 'Volunteer',
      'icon': Icons.people_rounded,
      'color': AppTheme.roleVolunteerAccent,
    },
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _passwordConfirmController.text,
      role: _role,
      firstName: _firstNameController.text.trim().isEmpty
          ? null
          : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      organization: _role == 'ngo'
          ? (_organizationController.text.trim().isEmpty
                ? null
                : _organizationController.text.trim())
          : null,
    );
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration successful. Please log in.'),
            backgroundColor: AppTheme.navy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else if (auth.error != null) {
        final msg = NetworkErrorHelper.toUserMessage(auth.error!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.navy,
            behavior: SnackBarBehavior.floating,
          ),
        );
        auth.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.error != null && !_hasShownStaleError) {
      _hasShownStaleError = true;
      final err = auth.error!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && auth.error != null) {
          final msg = NetworkErrorHelper.toUserMessage(err);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppTheme.navy,
              behavior: SnackBarBehavior.floating,
            ),
          );
          auth.clearError();
        }
      });
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.loginGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Scrollable form
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Join ShareCare',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in your details to get started',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Role selector
                          _SectionLabel(text: 'Choose your role'),
                          const SizedBox(height: 12),
                          Row(
                            children: roles.map((r) {
                              final selected = _role == r['value'];
                              final color = r['color'] as Color;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: r != roles.last ? 10 : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _role = r['value'] as String,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected ? color : Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMd,
                                        ),
                                        border: Border.all(
                                          color: selected
                                              ? color
                                              : Colors.grey.shade200,
                                          width: selected ? 2 : 1,
                                        ),
                                        boxShadow: selected
                                            ? AppTheme.colorShadow(color)
                                            : AppTheme.cardShadow,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            r['icon'] as IconData,
                                            color: selected
                                                ? Colors.white
                                                : color,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            r['label'] as String,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: selected
                                                  ? Colors.white
                                                  : AppTheme.navy,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 28),

                          // Account section
                          _SectionLabel(text: 'Account'),
                          const SizedBox(height: 12),
                          _GlassCard(
                            child: Column(
                              children: [
                                _StyledField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  icon: Icons.person_outline_rounded,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                _StyledField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _StyledField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    if (v.length < 8) {
                                      return 'At least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _StyledField(
                                  controller: _passwordConfirmController,
                                  label: 'Confirm password',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePasswordConfirm,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePasswordConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePasswordConfirm =
                                          !_obscurePasswordConfirm,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Personal details
                          _SectionLabel(text: 'Personal details'),
                          const SizedBox(height: 12),
                          _GlassCard(
                            child: Column(
                              children: [
                                _StyledField(
                                  controller: _firstNameController,
                                  label: 'First name',
                                  icon: Icons.badge_outlined,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                _StyledField(
                                  controller: _lastNameController,
                                  label: 'Last name',
                                  icon: Icons.badge_outlined,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                _StyledField(
                                  controller: _phoneController,
                                  label: 'Contact number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                                if (_role == 'ngo') ...[
                                  const SizedBox(height: 14),
                                  _StyledField(
                                    controller: _organizationController,
                                    label: 'Organization name',
                                    icon: Icons.business_rounded,
                                    validator: (v) =>
                                        _role == 'ngo' &&
                                            (v == null || v.trim().isEmpty)
                                        ? 'Required for NGO / Hospital'
                                        : null,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Submit button
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3A8DFF), Color(0xFF6C63FF)],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3A8DFF,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                onTap: auth.isLoading ? null : _submit,
                                child: Center(
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Create Account',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(
                                context,
                              ).pushReplacementNamed(AppRoutes.login),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Already have an account? ',
                                    ),
                                    TextSpan(
                                      text: 'Sign In',
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.accentPurple,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.accentYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryTeal,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.navy),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: AppTheme.textTertiary,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primaryTeal, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surfaceLightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: AppTheme.primaryTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.statusError),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
