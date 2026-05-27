import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reminder.dart';
import '../theme/app_colors.dart';
import '../widgets/quick_add_button.dart';
import '../widgets/reminder_row.dart';
import '../widgets/ring_painter.dart';

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
  final int _streak  = 6;

  late AnimationController _ringController;
  late Animation<double>    _ringAnimation;

  double get _progress {
    if (_goal == 0) return 0;
    return (_consumed / _goal).clamp(0.0, 1.0);
  }
  double get _remaining => math.max(0, _goal - _consumed);

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

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      print("NO USER LOGGED IN");
      setState(() {
        _name = "Not logged in";
        _goal = 0;
      });
      return;
    }

    print("USER ID: ${user.id}");

    final profile = await _supabaseService.getProfile();

    print("PROFILE: $profile");

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
                const SizedBox(height: 32),
                _buildProgressRing(),
                const SizedBox(height: 22),
                _buildQuickAdd(),
                // const SizedBox(height: 28), // STREAK
                // _buildStreakAndNext(),
                // const SizedBox(height: 28), //REMINDERS
                // _buildReminderHistory(),
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
                'Good morning,',
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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_outlined,
                  color: AppColors.text, size: 22),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Progress ring -----------------------------------------------

  Widget _buildProgressRing() {
    return Center(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _ringAnimation,
            builder: (context, _) {
              final animatedProgress = _progress * _ringAnimation.value;
              return SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: RingPainter(progress: animatedProgress),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.water_drop_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text:
                                '${(_consumed * _ringAnimation.value).round()}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                  letterSpacing: -1,
                                ),
                              ),
                              const TextSpan(
                                text: ' ml',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'of ${_goal.round()} ml',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     _StatPill(
          //       label: 'Consumed',
          //       value: '${_consumed.round()} ml',
          //       color: AppColors.primary,
          //       icon: Icons.check_circle_outline,
          //     ),
          //     const SizedBox(width: 12),
          //     _StatPill(
          //       label: 'Remaining',
          //       value: '${_remaining.round()} ml',
          //       color: AppColors.textMuted,
          //       icon: Icons.water_outlined,
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  //  Quick add -----------------------------------------------j

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

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: QuickAddButton(
                  icon: Icons.sports_bar_outlined,
                  amount: 500.0,
                  label: 'Bottle',
                  onTap: () {
                    _addWater(500.0);
                  },
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: QuickAddButton(
                  icon: Icons.local_drink_outlined,
                  amount: 750.0,
                  label: 'Large bottle',
                  onTap: () {
                    _addWater(750.0);
                  },
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: QuickAddButton(
                  icon: Icons.water_drop_rounded,
                  amount: 0,
                  label: 'Custom Bottle',
                  onTap: () {
                    _addWater(0);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Streak + next reminder -----------------------------------------------

  // Widget _buildStreakAndNext() {
  //   final next = sampleReminders
  //       .where((r) => r.status == ReminderStatus.upcoming)
  //       .firstOrNull;
  //
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _InfoCard(
  //           iconBg: AppColors.streakOrange.withOpacity(0.1),
  //           icon: Icons.local_fire_department,
  //           iconColor: AppColors.streakOrange,
  //           title: '$_streak days',
  //           subtitle: 'Streak',
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: _InfoCard(
  //           iconBg: AppColors.primaryLight,
  //           icon: Icons.alarm,
  //           iconColor: AppColors.primary,
  //           title: next?.time ?? '—',
  //           subtitle: 'Next reminder',
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Reminder history -----------------------------------------------

  // Widget _buildReminderHistory() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           const Expanded(
  //             child: Text(
  //               "Today's reminders",
  //               style: TextStyle(
  //                 fontSize: 15,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppColors.text,
  //                 letterSpacing: -0.2,
  //               ),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {},
  //             style: TextButton.styleFrom(
  //               padding: EdgeInsets.zero,
  //               minimumSize: Size.zero,
  //               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //             ),
  //             child: const Text(
  //               'See all',
  //               style: TextStyle(
  //                 fontSize: 13,
  //                 color: AppColors.primary,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 10),
  //
  //       // Reminder boxes Column -----------------------------------------------
  //
  //       Container(
  //         decoration: BoxDecoration(
  //           color: AppColors.surface,
  //           borderRadius: BorderRadius.circular(16),
  //           border: Border.all(color: AppColors.cardBorder),
  //         ),
  //         child: Column(
  //           children: sampleReminders.asMap().entries.map((entry) {
  //             final i = entry.key;
  //             final r = entry.value;
  //             return Column(
  //               children: [
  //                 ReminderRow(reminder: r),
  //                 if (i < sampleReminders.length - 1)
  //                   Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 16),
  //                     child: Divider(
  //                       height: 1,
  //                       thickness: 0.5,
  //                       color: AppColors.cardBorder,
  //                     ),
  //                   ),
  //               ],
  //             );
  //           }).toList(),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}

// Small reusable widgets -----------------------------------------------

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}