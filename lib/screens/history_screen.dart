import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../theme/app_colors.dart';
import '../widgets/reminder_row.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _weekData = [2800.0, 3100.0, 2400.0, 3400.0, 2900.0, 1200.0, 1850.0];
  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _goal     = 3200.0;

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
                const SizedBox(height: 18),
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your hydration over the past week',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                _buildWeeklyChart(),
                const SizedBox(height: 20),
                _buildStatCards(),
                const SizedBox(height: 28),
                _buildInsightCard(),
                const SizedBox(height: 28),
                _buildFullLog(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Weekly bar chart ─────────────────────────────────────────────────────

  Widget _buildWeeklyChart() {
    final maxVal = _weekData.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This week',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_weekData.length, (i) {
                final isToday  = i == _weekData.length - 1;
                final hitGoal  = _weekData[i] >= _goal;
                final barH     = (_weekData[i] / maxVal) * 88;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // ml label on top of bar
                        Text(
                          '${(_weekData[i] / 1000).toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontSize: 8,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textLight,
                            fontWeight: isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Bar
                        AnimatedContainer(
                          duration: Duration(milliseconds: 400 + i * 60),
                          curve: Curves.easeOut,
                          height: barH,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : hitGoal
                                ? AppColors.primaryMid
                                : AppColors.ringTrack,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Day label
                        Text(
                          _weekDays[i],
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontWeight: isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            children: [
              _LegendDot(color: AppColors.primary, label: 'Today'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.primaryMid, label: 'Goal met'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.ringTrack, label: 'Below goal'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stat cards ───────────────────────────────────────────────────────────

  Widget _buildStatCards() {
    final goalsHit = _weekData.where((v) => v >= _goal).length;
    final avg = _weekData.reduce((a, b) => a + b) / _weekData.length;
    final best = _weekData.reduce((a, b) => a > b ? a : b);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          label: 'Avg daily',
          value: '${avg.round()} ml',
          sub: 'this week',
          icon: Icons.show_chart,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'Best day',
          value: '${best.round()} ml',
          sub: 'Thursday',
          icon: Icons.emoji_events_outlined,
          color: AppColors.streakOrange,
        ),
        _StatCard(
          label: 'Goal met',
          value: '$goalsHit / 7',
          sub: 'days',
          icon: Icons.check_circle_outline,
          color: AppColors.successGreen,
        ),
        _StatCard(
          label: 'Current streak',
          value: '6 days',
          sub: 'keep going',
          icon: Icons.local_fire_department_outlined,
          color: AppColors.streakOrange,
        ),
      ],
    );
  }

  // ─── Insight card ─────────────────────────────────────────────────────────

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryMid.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly insight',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You tend to miss hydration between 2–5 PM. Try setting a gentle reminder at 2:30 PM on weekdays.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.text,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Full reminder log ────────────────────────────────────────────────────

  Widget _buildFullLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's full log",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            letterSpacing: -0.2,
          ),
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

// ─── Small helpers ────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
            const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}