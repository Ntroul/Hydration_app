import 'package:flutter/material.dart';
import 'package:hydration_app/screens/trees_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';
import '../theme/app_colors.dart';
import '../widgets/quick_add_button.dart';
import '../widgets/reminder_row.dart';

import 'dart:math' as math;

import '../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  double _goal = 0;
  String _name = '';
  double _consumed   = 0;

  late AnimationController _ringController;
  late Animation<double>    _ringAnimation;

  double get _progress {
    if (_goal <= 0) return 0.0;
    return (_consumed / _goal).clamp(0.0, 1.0);
  }
  // double get _remaining => math.max(0, _goal - _consumed);

  @override
  void initState() {
    super.initState();

    _loadProfile();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );

    _ringController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _addWater(double ml) {
    setState(() => _consumed = math.min(_consumed + ml, _goal));
    _ringController
      ..reset()
      ..forward();
  }
  void _resetWater() {
    setState(() {
      _consumed = 0;
    });
    _ringController
      ..reset()
      ..forward();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    final profile = await _supabaseService.getProfile();

    setState(() {
      _name = profile['name'] ?? 'No name';
      _goal = (profile['daily_goal'] ?? 0).toDouble();
    });
  }

  //  Build -----------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildHeader(),

                const SizedBox(height: 24),
                _buildPlantTank(),

                const SizedBox(height: 16),
                _buildProgressInfo(),

                const SizedBox(height: 28),
                _buildStreakAndNext(),

                const SizedBox(height: 28),
                _buildQuickAdd(),

                const SizedBox(height: 28),
                _buildReminderHistory(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //  Header -----------------------------------------------

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome,',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
               Text(
                _name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        // more trees screen
        GestureDetector(
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(
                builder: (_) =>
            TreesScreen())
            );
          },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textMuted),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(2),
                  child: const Image(
                    image: AssetImage('assets/plants/tree4.jpeg'),
                ),
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }

  // plant and bar
  Widget _buildPlantTank() {
    return AnimatedBuilder(
      animation: _ringAnimation,
      builder: (context, _) {
        // final progress = _progress;

        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [

              // tree
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 900),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Image.asset(
                      _plantAsset,
                      key: ValueKey(_plantAsset),
                      height: 150, //180
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // tank
              SizedBox(
                width: 80,
                height: 200, //220
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [

                    // water
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: SizedBox(
                        width: 80,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 220 * _progress,
                              child: Image.asset(
                                'assets/tank/water.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // tank frame
                    Container(
                      width: 80,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.grey,
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
  String get _plantAsset {
    final progress = _progress;

    if (progress < 0.20) {
      return 'assets/plants/tree.jpeg';
    }

    if (progress < 0.40) {
      return 'assets/plants/tree1.jpeg';
    }

    if (progress < 0.60) {
      return 'assets/plants/tree2.jpeg';
    }

    if (progress < 0.80) {
      return 'assets/plants/tree3.jpeg';
    }
    return 'assets/plants/tree4.jpeg';
  }

  Widget _buildProgressInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            '${_consumed.round()} / ${_goal.round()} ml',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${(_progress * 100).round()}% completed',
            style: const TextStyle(
              color: AppColors.textMuted,
            ),
          ),
        ],
      )
    );
  }


  //  Quick add -----------------------------------------------

  Widget _buildQuickAdd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick add',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: QuickAddButton(
                  icon: Icons.water_drop_outlined,
                  amount: 250.0,
                  label: 'Glass',
                  onTap: () {
                    _addWater(250.0);
                  },
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _resetWater,
              child: const Text('Reset'),
            )
          ],
        ),
      ],
    );
  }

  // Streak + next reminder -----------------------------------------------

  Widget _buildStreakAndNext() {
    final next = sampleReminders
        .where((r) => r.status == ReminderStatus.upcoming)
        .firstOrNull;

    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            iconBg: AppColors.primaryLight,
            icon: Icons.alarm,
            iconColor: AppColors.primary,
            title: next?.time ?? '—',
            subtitle: 'Next reminder',
          ),
        ),
      ],
    );
  }

  // Reminder history -----------------------------------------------

  Widget _buildReminderHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Today's reminders",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Reminder boxes Column -----------------------------------------------

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: sampleReminders.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              return Column(
                children: [
                  ReminderRow(reminder: r),
                  if (i < sampleReminders.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.cardBorder,
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// streak or reminders

class _InfoCard extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),

          const SizedBox(height: 8),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}