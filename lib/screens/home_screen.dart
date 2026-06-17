import 'package:flutter/material.dart';
import 'package:hydration_app/screens/trees_screen.dart';
import '../models/reminder.dart';
import '../services/notification_services.dart';
import '../theme/app_colors.dart';
import '../widgets/reminder_row.dart';

import 'dart:math' as math;

import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  double _goal     = 0;
  String _name     = '';
  double _consumed = 0;

  final _supabase = Supabase.instance.client;

  late AnimationController _fillController;
  late Animation<double>   _fillAnimation;

  double get _progress {
    if (_goal <= 0) return 0.0;
    return (_consumed / _goal).clamp(0.0, 1.0);
  }

  double get _remaining => math.max(0, _goal - _consumed);

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String get _motivationText {
    final p = _progress;
    if (p == 0)   return 'Start your day hydrated';
    if (p < 0.25) return 'Great start — keep it up!';
    if (p < 0.5)  return 'You\'re building momentum';
    if (p < 0.75) return 'More than halfway there!';
    if (p < 1.0)  return 'Almost there — finish strong!';
    return 'Goal reached! Amazing work!';
  }

  Color get _progressColor {
    final p = _progress;
    if (p < 0.35) return const Color(0xFF378ADD);
    if (p < 0.70) return const Color(0xFF1D9E75);
    return const Color(0xFF639922);
  }

  @override
  void initState() {
    super.initState();

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeOutCubic,
    );

    _loadData();

    _fillController.forward();
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  Future<void> _addWater(double ml) async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    await _supabase.from('water_logs').insert({
      'user_id': user.id,
      'amount': ml.toInt(),
    });

    setState(() {
      _consumed += ml;
    });

    _fillController
      ..reset()
      ..forward();
  }

  Future<void> _undoLastDrink() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    final lastDrink = await _supabase
        .from('water_logs')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .single();

    await _supabase
        .from('water_logs')
        .delete()
        .eq('id', lastDrink['id']);

    setState(() {
      _consumed -= (lastDrink['amount'] as num).toDouble();

      if (_consumed < 0) {
        _consumed = 0;
      }
    });

    _fillController
      ..reset()
      ..forward();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    final profile = await _supabaseService.getProfile();
    setState(() {
      _name = profile['name'] ?? 'Friend';
      _goal = (profile['daily_goal'] ?? 0).toDouble();
    });
  }
  
  Future<void> _loadData() async {
    await _loadProfile();

    final user = _supabase.auth.currentUser;

    if (user == null) return;

    final today = DateTime.now();

    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final logs = await _supabase
        .from('water_logs')
        .select()
        .eq('user_id', user.id);
        // .gte('created_at', startOfDay.toIso8601String());

    double total = 0;

    for (final log in logs) {
      total += (log['amount'] as num).toDouble();
    }

    setState(() {
      _consumed = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildTopBanner(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildPlantTank(),
                    const SizedBox(height: 16),
                    _buildProgressBar(),
                    const SizedBox(height: 20),
                    _buildStatsRow(),

                    const SizedBox(height: 24),
                    _buildQuickAdd(),
                    const SizedBox(height: 24),
                    _buildReminderHistory(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: _progressColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _motivationText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => TreesScreen())),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              ),
              child: ClipOval(
                child: const Image(
                  image: AssetImage('assets/plants/tree4.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTank() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Image.asset(
                    _plantAsset,
                    key: ValueKey(_plantAsset),
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                _PlantStageLabel(progress: _progress),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _progressColor,
                ),
                child: Text('${_consumed.round()}'),
              ),
              const Text('ml',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),

              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 56,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: _progressColor.withValues(alpha: 0.35), width: 2),
                      color: _progressColor.withValues(alpha: 0.05),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: SizedBox(
                      width: 52,
                      height: 176,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 176 * _progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _progressColor.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    height: 180,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (_) => Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 10, height: 0.8,
                            color: _progressColor.withValues(alpha: 0.25),
                          ),
                        ],
                      )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${(_progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _progress > 0.45
                            ? Colors.white
                            : _progressColor,
                      ),
                    ),
                  ),
                ],
              ),

              Text(
                '${_goal.round()} ml',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _progressColor,
                ),
                child: Text('${_consumed.round()} ml consumed'),
              ),
              const Spacer(),
              Text(
                '${_remaining.round()} ml left',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.ringTrack,
                valueColor:
                AlwaysStoppedAnimation<Color>(_progressColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            const Spacer(),
            //--------temp button
            // ElevatedButton(
            // onPressed: () async {
            //   await NotificationService.showTestNotification();
            // },
            // child: const Text("TEST"),
            // ),
            // ElevatedButton(
            //   onPressed: () async {
            //     final pending =
            //     await NotificationService.getPendingNotifications();
            //
            //     print("Pending count: ${pending.length}");
            //
            //     for (final p in pending) {
            //       print("ID: ${p.id}");
            //       print("Title: ${p.title}");
            //     }
            //   },
            //   child: const Text("Check"),
            // ),
            ElevatedButton(
              onPressed: () async {
                await NotificationService.scheduleReminder(
                  id: 1,
                  minutes: 1,
                );
              },
              child: const Text("1min"),
            ),
            //-----------
            GestureDetector(
              onTap: _undoLastDrink,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFF09595), width: 0.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 13, color: Color(0xFFA32D2D)),
                    SizedBox(width: 4),
                    Text('Undo last drink',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA32D2D),
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () => _addWater(250),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _progressColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _progressColor.withValues(alpha: 0.30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: _progressColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add 250 ml',
                  style: TextStyle(
                    fontSize: 14,
                    color: _progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildStatsRow() {
    final next = sampleReminders
        .where((r) => r.status == ReminderStatus.upcoming)
        .firstOrNull;

    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.alarm_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.primaryLight,
            label: 'Next reminder',
            value: next?.time ?? '—',
          ),
        ),
      ],
    );
  }

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
              child: const Text('See all',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                          color: AppColors.cardBorder),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String get _plantAsset {
    final p = _progress;
    if (p < 0.20) return 'assets/plants/tree.jpeg';
    if (p < 0.40) return 'assets/plants/tree1.jpeg';
    if (p < 0.60) return 'assets/plants/tree2.jpeg';
    if (p < 0.80) return 'assets/plants/tree3.jpeg';
    return 'assets/plants/tree4.jpeg';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   label;
  final String   value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlantStageLabel extends StatelessWidget {
  final double progress;
  const _PlantStageLabel({required this.progress});

  String get _label {
    if (progress < 0.20) return 'Seedling';
    if (progress < 0.40) return 'Sprouting';
    if (progress < 0.60) return 'Growing';
    if (progress < 0.80) return 'Thriving';
    return 'Full bloom';
  }

  Color get _color {
    if (progress < 0.20) return const Color(0xFF888780);
    if (progress < 0.40) return const Color(0xFF639922);
    if (progress < 0.60) return const Color(0xFF1D9E75);
    if (progress < 0.80) return const Color(0xFF378ADD);
    return const Color(0xFF639922);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_label),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      ),
    );
  }
}