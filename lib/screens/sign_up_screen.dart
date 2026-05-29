import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydration_app/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';


class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegister;
  final VoidCallback onGoToLogin;

  const RegisterScreen({
    super.key,
    required this.onRegister,
    required this.onGoToLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // Controllers
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  // Focus nodes
  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _isLoading       = false;
  bool _agreedToTerms   = false;

  // Password strength
  double get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    double score = 0;
    if (p.length >= 8)                          score += 0.25;
    if (p.contains(RegExp(r'[A-Z]')))           score += 0.25;
    if (p.contains(RegExp(r'[0-9]')))           score += 0.25;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score += 0.25;
    return score;
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s <= 0.25) return Colors.redAccent;
    if (s <= 0.50) return AppColors.streakOrange;
    if (s <= 0.75) return Colors.amber;
    return AppColors.successGreen;
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s == 0)    return '';
    if (s <= 0.25) return 'Weak';
    if (s <= 0.50) return 'Fair';
    if (s <= 0.75) return 'Good';
    return 'Strong';
  }

  // Entry animation
  late AnimationController _entryController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
        parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();

    // Rebuild on password change to update strength indicator
    _passwordController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocus);
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  String? _validate() {
    final name     = _nameController.text;
    final email    = _emailController.text;
    final password = _passwordController.text;
    final confirm  = _confirmController.text;

    if (name.isEmpty)             return 'Please enter your full name';
    if (name.length < 2)          return 'Name is too short';
    if (email.isEmpty)            return 'Please enter your email';
    if (!email.contains('@'))     return 'Enter a valid email address';
    if (password.length < 6)      return 'Password must be at least 6 characters';
    if (password != confirm)      return 'Passwords do not match';
    if (!_agreedToTerms)          return 'Please agree to the Terms & Privacy Policy';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final error = _validate();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully'),
          ),
        );

        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.cardBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    _buildLogo(),
                    const SizedBox(height: 28),
                    _buildHeading(),
                    const SizedBox(height: 32),
                    _buildNameField(),
                    const SizedBox(height: 14),
                    _buildEmailField(),
                    const SizedBox(height: 14),
                    _buildPasswordField(),

                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildStrengthBar(),
                    ],

                    const SizedBox(height: 14),
                    _buildConfirmField(),
                    const SizedBox(height: 20),
                    _buildTermsRow(),
                    const SizedBox(height: 28),
                    _buildRegisterButton(),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildSocialButtons(),
                    const SizedBox(height: 36),
                    _buildLoginRow(),
                    const SizedBox(height: 24),
                  ],

                ),
              ),
            ),
          ),
        ),
      )
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.water_drop,
              color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Hydration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Coach',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Heading ──────────────────────────────────────────────────────────────

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Create your account',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            letterSpacing: -0.8,
            height: 1.15,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Start building your hydration habit today',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ─── Fields ───────────────────────────────────────────────────────────────

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold
          ),
        ),
        _AuthField(
          controller:      _nameController,
          focusNode:       _nameFocus,
          label:           'Full name',
          hint:            'Alex Johnson',
          icon:            Icons.person_outline_rounded,
          inputType:       TextInputType.name,
          capitalization:  TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onSubmitted:     (_) =>
              FocusScope.of(context).requestFocus(_emailFocus),

        ),
      ]
    );
  }

  Widget _buildEmailField() {
    return _AuthField(
      controller:      _emailController,
      focusNode:       _emailFocus,
      label:           'Email address',
      hint:            'you@example.com',
      icon:            Icons.mail_outline_rounded,
      inputType:       TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onSubmitted:     (_) =>
          FocusScope.of(context).requestFocus(_passwordFocus),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold
          ),
        ),
        _AuthField(
          controller:      _passwordController,
          focusNode:       _passwordFocus,
          label:           'Password',
          hint:            '••••••••',
          icon:            Icons.lock_outline_rounded,
          obscureText:     _obscurePassword,
          textInputAction: TextInputAction.next,
          onSubmitted:     (_) =>
              FocusScope.of(context).requestFocus(_confirmFocus),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ]
    );
  }

  Widget _buildConfirmField() {
    // Shows a checkmark when passwords match
    final match = _confirmController.text.isNotEmpty &&
        _confirmController.text == _passwordController.text;

    return _AuthField(
      controller:      _confirmController,
      focusNode:       _confirmFocus,
      label:           'Confirm password',
      hint:            '••••••••',
      icon:            Icons.lock_outline_rounded,
      obscureText:     _obscureConfirm,
      textInputAction: TextInputAction.done,
      onSubmitted:     (_) => _submit(),
      onChanged:       (_) => setState(() {}),
      suffixIcon: match
          ? const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.check_circle_outline,
            color: AppColors.successGreen, size: 20),
      )
          : IconButton(
        icon: Icon(
          _obscureConfirm
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
        onPressed: () =>
            setState(() => _obscureConfirm = !_obscureConfirm),
      ),
    );
  }

  // ─── Password strength bar ────────────────────────────────────────────────

  Widget _buildStrengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            minHeight: 4,
            backgroundColor: AppColors.ringTrack,
            valueColor:
            AlwaysStoppedAnimation<Color>(_strengthColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text(
              'Password strength: ',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textMuted),
            ),
            Text(
              _strengthLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _strengthColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Terms checkbox ───────────────────────────────────────────────────────

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _agreedToTerms
                  ? AppColors.primary
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreedToTerms
                    ? AppColors.primary
                    : AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: _agreedToTerms
                ? const Icon(Icons.check,
                color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Register button ──────────────────────────────────────────────────────

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GestureDetector(
        onTap: _isLoading ? null : _submit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : const Text(
              'Create account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Divider ──────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
            child:
            Divider(thickness: 0.5, color: AppColors.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or sign up with',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted.withValues(alpha: 0.8)),
          ),
        ),
        Expanded(
            child:
            Divider(thickness: 0.5, color: AppColors.cardBorder)),
      ],
    );
  }

  // ─── Social buttons ───────────────────────────────────────────────────────

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            onTap: widget.onRegister,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: 'Apple',
            icon: Icons.apple_rounded,
            onTap: widget.onRegister,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginRow() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Already have an account? ',
            style:
            TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LoginScreen(onLogin: () {}, onGoToRegister: () {}))
              );
            },
            child: const Text(
              'Sign in',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable auth text field ─────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController     controller;
  final FocusNode                 focusNode;
  final String                    label;
  final String                    hint;
  final IconData                  icon;
  final TextInputType             inputType;
  final bool                      obscureText;
  final Widget?                   suffixIcon;
  final TextInputAction           textInputAction;
  final ValueChanged<String>?     onSubmitted;
  final ValueChanged<String>?     onChanged;
  final TextCapitalization        capitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _AuthField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.inputType       = TextInputType.text,
    this.obscureText     = false,
    this.suffixIcon,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.capitalization  = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:          controller,
      focusNode:           focusNode,
      keyboardType:        inputType,
      obscureText:         obscureText,
      textInputAction:     textInputAction,
      textCapitalization:  capitalization,
      inputFormatters:     inputFormatters,
      onSubmitted:         onSubmitted,
      onChanged:           onChanged,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.text,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(
            color: AppColors.textMuted, fontSize: 14),
        hintStyle: const TextStyle(
            color: AppColors.textLight, fontSize: 15),
        filled:      true,
        fillColor:   AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ─── Social sign-in button ────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.text, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}