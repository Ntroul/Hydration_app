import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _smartReminders  = true;
  bool _quietHours      = true;
  bool _workoutNudge    = false;
  bool _weatherGoal     = true;
  bool _wristVibration  = false;
  bool _healthConnect   = true;

  double _weightKg      = 75;
  int    _activityLevel = 1; // 0 = low, 1 = moderate, 2 = high

  static const _activityLabels = ['Low', 'Moderate', 'High'];

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
                  'Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                _buildGoalCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('Profile'),
                _buildProfileCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('Reminders'),
                _buildRemindersCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('Integrations'),
                _buildIntegrationsCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('Display'),
                _buildDisplayCard(),
                const SizedBox(height: 32),
                _buildAppInfo(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Computed daily goal ──────────────────────────────────────────────────

  double get _computedGoal {
    double base = _weightKg * 33;
    if (_activityLevel == 1) base += 350;
    if (_activityLevel == 2) base += 700;
    // Athens heat bonus
    base += 200;
    return (base / 100).round() * 100;
  }

  // ─── Goal card ────────────────────────────────────────────────────────────

  Widget _buildGoalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryMid.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily goal',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_computedGoal.round()} ml',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                'Adjusted for Athens heat · 34°C',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Name row
          _SettingsRow(
            icon: Icons.person_outline,
            title: 'Name',
            trailing: const Text('Alex',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          _divider(),
          // Weight slider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monitor_weight_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Weight',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text,
                          )),
                    ),
                    Text(
                      '${_weightKg.round()} kg',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.ringTrack,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.1),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _weightKg,
                    min: 40,
                    max: 130,
                    onChanged: (v) => setState(() => _weightKg = v),
                  ),
                ),
              ],
            ),
          ),
          _divider(),
          // Activity level
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_run_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    const Text('Activity level',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        )),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(3, (i) {
                    final active = _activityLevel == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _activityLevel = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.cardBorder,
                              ),
                            ),
                            child: Text(
                              _activityLabels[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: active
                                    ? AppColors.surface
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.location_on_outlined,
            title: 'Location',
            trailing: const Text('Athens, GR',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  // ─── Reminders ────────────────────────────────────────────────────────────

  Widget _buildRemindersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.access_time_outlined,
            title: 'Smart reminders',
            subtitle: 'Every 90 min, 7 AM – 10 PM',
            value: _smartReminders,
            onChanged: (v) => setState(() => _smartReminders = v),
          ),
          _divider(),
          _ToggleRow(
            icon: Icons.bedtime_outlined,
            title: 'Quiet hours',
            subtitle: '10 PM – 7 AM — no notifications',
            value: _quietHours,
            onChanged: (v) => setState(() => _quietHours = v),
          ),
          _divider(),
          _ToggleRow(
            icon: Icons.fitness_center_outlined,
            title: 'Post-workout nudge',
            subtitle: '+400 ml reminder after activity',
            value: _workoutNudge,
            onChanged: (v) => setState(() => _workoutNudge = v),
          ),
          _divider(),
          _ToggleRow(
            icon: Icons.wb_sunny_outlined,
            title: 'Weather-based goal',
            subtitle: 'Raises target on hot days',
            value: _weatherGoal,
            onChanged: (v) => setState(() => _weatherGoal = v),
          ),
          _divider(),
          _ToggleRow(
            icon: Icons.watch_outlined,
            title: 'Wrist vibration only',
            subtitle: 'Silent alerts on Wear OS',
            value: _wristVibration,
            onChanged: (v) => setState(() => _wristVibration = v),
          ),
        ],
      ),
    );
  }

  // ─── Integrations ─────────────────────────────────────────────────────────

  Widget _buildIntegrationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.favorite_border,
            title: 'Health Connect',
            subtitle: 'Sync with Android Health',
            value: _healthConnect,
            onChanged: (v) => setState(() => _healthConnect = v),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.watch_outlined,
            title: 'Wear OS',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.ringTrack,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Not connected',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Display ──────────────────────────────────────────────────────────────

  Widget _buildDisplayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.opacity,
            title: 'Units',
            trailing: const Text('ml',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.schedule_outlined,
            title: 'Time format',
            trailing: const Text('24h',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.palette_outlined,
            title: 'Theme',
            trailing: const Text('Light · Blue',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  // ─── App info ─────────────────────────────────────────────────────────────

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 10),
          const Text('Hydration Coach',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          const Text('Version 1.0.0',
              style:
              TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0),
    child: Divider(height: 1, thickness: 0.5, color: AppColors.cardBorder),
  );

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Shared row widgets ───────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                )),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    )),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
            inactiveThumbColor: AppColors.textLight,
            inactiveTrackColor: AppColors.ringTrack,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}