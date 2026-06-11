import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.profile,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form values
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();

  // Per-step focus nodes so keyboard opens automatically
  final _nameFocus = FocusNode();
  final _ageFocus = FocusNode();
  final _weightFocus = FocusNode();

  // Slide+fade animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();

    // Auto-focus name field on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocus);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _nameFocus.dispose();
    _ageFocus.dispose();
    _weightFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  String? _validateCurrent() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.isEmpty) return 'Please enter your name';
        if (_nameController.text.length < 2) return 'Name is too short';
        return null;
      case 1:
        final age = int.tryParse(_ageController.text);
        if (age == null) return 'Please enter a valid age';
        if (age < 5 || age > 120) return 'Enter an age between 5 and 120';
        return null;
      case 2:
        final w = double.tryParse(_weightController.text);
        if (w == null) return 'Please enter a valid weight';
        if (w < 20 || w > 300) return 'Enter a weight between 20 and 300 kg';
        return null;
    }
    return null;
  }

  void _next() {
    final error = _validateCurrent();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
      _animController
        ..reset()
        ..forward();

      // Focus next field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentStep == 1) FocusScope.of(context).requestFocus(_ageFocus);
        if (_currentStep == 2)
          FocusScope.of(context).requestFocus(_weightFocus);
      });
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
      _animController
        ..reset()
        ..forward();
    }
  }

  Future<void> _finish() async {
    final user = Supabase.instance.client.auth.currentUser;

    await Supabase.instance.client.from('profiles').upsert({
      'id': user!.id,
      'name': _nameController.text,
      'age': int.parse(_ageController.text),
      'weight': double.parse(_weightController.text),
      'daily_goal': 2500,
    });

    widget.profile.completeOnboarding(
      name: _nameController.text,
      age: int.parse(_ageController.text),
      weightKg: double.parse(_weightController.text),
    );

    widget.onComplete();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildProgressDots(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepPage(
                    fadeAnim: _fadeAnim,
                    slideAnim: _slideAnim,
                    child: _buildNameStep(),
                  ),
                  _StepPage(
                    fadeAnim: _fadeAnim,
                    slideAnim: _slideAnim,
                    child: _buildAgeStep(),
                  ),
                  _StepPage(
                    fadeAnim: _fadeAnim,
                    slideAnim: _slideAnim,
                    child: _buildWeightStep(),
                  ),
                  // _StepPage(
                  //     fadeAnim: _fadeAnim,
                  //     slideAnim: _slideAnim,
                  //     child: _buildLocationStep
                  // ),
                ],
              ),
            ),
            _buildBottomBar(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─── Progress dots ────────────────────────────────────────────────────────

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == _currentStep;
        final done = i < _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done || active ? AppColors.primary : AppColors.ringTrack,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ─── Step: Name ───────────────────────────────────────────────────────────

  Widget _buildNameStep() {
    return _StepContent(
      icon: Icons.person_outline,
      title: 'What\'s your name?',
      subtitle: 'We\'ll use this to personalise your experience',
      field: _OnboardingField(
        controller: _nameController,
        focusNode: _nameFocus,
        hint: 'e.g. Alex',
        label: 'Full name',
        inputType: TextInputType.name,
        capitalization: TextCapitalization.words,
        onSubmit: _next,
      ),
    );
  }

  // ─── Step: Age ────────────────────────────────────────────────────────────

  Widget _buildAgeStep() {
    return _StepContent(
      icon: Icons.cake_outlined,
      title: 'How old are you?',
      subtitle: 'Age helps us fine-tune your hydration goal',
      field: _OnboardingField(
        controller: _ageController,
        focusNode: _ageFocus,
        hint: 'e.g. 28',
        label: 'Age (years)',
        inputType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmit: _next,
      ),
    );
  }

  // ─── Step: Weight ─────────────────────────────────────────────────────────

  Widget _buildWeightStep() {
    return _StepContent(
      icon: Icons.monitor_weight_outlined,
      title: 'What\'s your weight?',
      subtitle: 'Weight is the biggest factor in your daily water goal',
      field: _OnboardingField(
        controller: _weightController,
        focusNode: _weightFocus,
        hint: 'e.g. 70',
        label: 'Weight (kg)',
        inputType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
        ],
        onSubmit: _next,
      ),
      bottomNote: '🔒 Stored only on your device. Never shared.',
    );
  }

  // Widget _buildLocationStep(){
  //   return _StepContent(
  //     icon: Icons.monitor_weight_outlined,
  //     title: 'What\'s your weight?',
  //     subtitle: 'Weight is the biggest factor in your daily water goal',
  //     field: _OnboardingField(
  //       controller: _weightController,
  //       focusNode: _weightFocus,
  //       hint: 'e.g. 70',
  //       label: 'Weight (kg)',
  //       inputType: const TextInputType.numberWithOptions(decimal: true),
  //       inputFormatters: [
  //         FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
  //       ],
  //       onSubmit: _next,
  //     ),
  //     bottomNote: '🔒 Stored only on your device. Never shared.',
  //   );
  // }


  // ─── Bottom bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final isLast = _currentStep == 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          // Back button — hidden on first step
          AnimatedOpacity(
            opacity: _currentStep > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _currentStep > 0 ? _back : null,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.text,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Continue / Get started button
          Expanded(
            child: GestureDetector(
              onTap: _next,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isLast ? 'Get started' : 'Continue',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
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

// ─── Reusable step wrapper ────────────────────────────────────────────────────

class _StepPage extends StatelessWidget {
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final Widget child;

  const _StepPage({
    required this.fadeAnim,
    required this.slideAnim,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(position: slideAnim, child: child),
    );
  }
}

class _StepContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget field;
  final String? bottomNote;

  const _StepContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.field,
    this.bottomNote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          // Icon badge
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 36),
          field,
          if (bottomNote != null) ...[
            const SizedBox(height: 16),
            Text(
              bottomNote!,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Styled text field ────────────────────────────────────────────────────────

class _OnboardingField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final String label;
  final TextInputType inputType;
  final TextCapitalization capitalization;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback onSubmit;

  const _OnboardingField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.label,
    required this.inputType,
    required this.onSubmit,
    this.capitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: inputType,
      textCapitalization: capitalization,
      inputFormatters: inputFormatters,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 18),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
