import 'package:flutter/material.dart';
import 'package:hydration_app/screens/sign_up_screen.dart';
import '../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/social_button.dart';

import '../widgets/auth_field.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onGoToRegister;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onGoToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
    ).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_emailController.text.isEmpty){
      return 'Please enter your email';
    }
    if (!_emailController.text.contains('@')){
      return 'Enter a valid email address';
    }
    if (_passwordController.text.length < 6){
      return 'Password must be at least 6 characters';
    }
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
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
        widget.onLogin();
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),

                  _buildLogo(),

                  const SizedBox(height: 40),

                  Container(
                    width: double.infinity,
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

                        _buildHeading(),
                        const SizedBox(height: 36),
                        _buildEmailField(),
                        const SizedBox(height: 14),
                        _buildPasswordField(),
                        const SizedBox(height: 10),
                        _buildForgotPassword(),
                        const SizedBox(height: 32),
                        _buildLoginButton(),
                        const SizedBox(height: 24),
                        _buildDivider(),
                        const SizedBox(height: 24),
                        _buildSocialButtons(),
                        const SizedBox(height: 40),
                        _buildRegisterRow(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Welcome back ',
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
          'Sign in to continue',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          'Email',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        AuthField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: 'Email address',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          inputType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_passwordFocus),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        AuthField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {}, // FIX FORGOT PASSWORD
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
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
              'Sign in',
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

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
            child: Divider(thickness: 0.5, color: AppColors.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted.withValues(alpha: 0.8)),
          ),
        ),
        Expanded(
            child: Divider(thickness: 0.5, color: AppColors.cardBorder)),
      ],
    );
  }

  //----------------------------------------------------------------------------
  // temporary Social Buttons

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: SocialButton(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            onTap: widget.onLogin,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SocialButton(
            label: 'Apple',
            icon: Icons.apple_rounded,
            onTap: widget.onLogin,
          ),
        ),
      ],
    );
  }

  //----------------------------------------------------------------------------

  Widget _buildRegisterRow() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RegisterScreen(onRegister: () {}, onGoToLogin: () {},),
                ),
              );
            },
            child: const Text(
              'Sign up',
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
