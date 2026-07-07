import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/notification_services.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile profile;


  const SettingsScreen({super.key, required this.profile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  final SupabaseService _supabaseService = SupabaseService();
  bool _notificationsEnabled = true;
  int _reminderMinutes = 60;
  TimeOfDay _wakeTime  = const TimeOfDay(hour: 8,  minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 0);
  int _activityLevel   = 1;

  static const _activityLabels = ['Low', 'Moderate', 'High'];

  UserProfile get _p => widget.profile;

  double get _computedGoal {
    double base = _p.weightKg * 33;
    if (_activityLevel == 1) base += 350;
    if (_activityLevel == 2) base += 700;
    base += 200;
    return (base / 100).round() * 100;
  }

  Future<void> _loadSettings() async {
    final data = await _supabaseService.getProfile();

    setState(() {
      _activityLevel = int.tryParse(data['activity_level'].toString()) ?? 1;
    });

    _p.updateWeight((data['weight'] as num).toDouble());
    _p.updateWeight((data['weight'] as num).toDouble());
    _p.updateAge(data['age'] ?? 0);
  }

  Future<void> _saveSettings() async {
    try {
      await _supabaseService.updateProfile({
        'name': _p.name,
        'age': _p.age,
        'weight': _p.weightKg,
        'activity_level': _activityLevel,
        'location': _p.location,
        'daily_goal': _computedGoal,

        'notifications_enabled': _notificationsEnabled,
        'reminder_minutes': _reminderMinutes,
        'wake_time': _wakeTime.format(context),
        'sleep_time': _sleepTime.format(context),

      });

      if (_notificationsEnabled) {
        await NotificationService.scheduleDailyReminders(
          wakeTime: _wakeTime,
          sleepTime: _sleepTime,
          intervalMinutes: _reminderMinutes,
        );
      } else {
        await NotificationService.cancelAll();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  void _showEditSheet({
    required String title,
    required String initialValue,
    required String suffix,
    required TextInputType keyboardType,
    required void Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: keyboardType,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text),
              decoration: InputDecoration(
                suffixText: suffix,
                suffixStyle: const TextStyle(
                    fontSize: 16, color: AppColors.textMuted),
                hintText: '0',
                hintStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
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
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
              onSubmitted: (v) {
                onSave(v);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  onSave(controller.text);
                  Navigator.pop(context);
                },
                child: const Text('Save',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _p,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    const Text('Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                          letterSpacing: -0.5,
                        )),
                    const SizedBox(height: 24),
                    _buildGoalCard(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Profile'),
                    _buildProfileCard(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Reminders'),
                    _buildRemindersCard(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Display'),
                    _buildDisplayCard(),
                    const SizedBox(height: 32),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saveSettings,
                        child: const Text(
                          'Save All Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildAppInfo(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryMid.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily goal',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500)),
              Text('${_computedGoal.round()} ml',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      letterSpacing: -0.5)),
            ],
          ),
        ],
      ),
    );
  }

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
          _SettingsRow(
            icon: Icons.person_outline,
            title: 'Name',
            trailing: Text(
              _p.name.isEmpty ? '—' : _p.name,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ),

          _divider(),

          _SettingsRow(
            icon: Icons.cake_outlined,
            title: 'Age',
            trailing: GestureDetector(
              onTap: () => _showEditSheet(
                title: 'Edit age',
                initialValue: _p.age == 0 ? '' : _p.age.toString(),
                suffix: 'yrs',
                keyboardType: TextInputType.number,
                  onSave: (v) async {
                    final age = int.tryParse(v);

                    if (age == null) return;

                    _p.updateAge(age);

                    await _supabaseService.updateProfile({
                      'age': age,
                    });
                  }
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryMid
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _p.age == 0 ? 'Set age' : '${_p.age} yrs',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _p.age == 0
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined,
                        size: 12,
                        color: _p.age == 0
                            ? AppColors.textMuted
                            : AppColors.primary),
                  ],
                ),
              ),
            ),
          ),

          _divider(),

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
                              color: AppColors.text)),
                    ),
                    Text('${_p.weightKg.round()} kg',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.ringTrack,
                    thumbColor: AppColors.primary,
                    overlayColor:
                    AppColors.primary.withValues(alpha: 0.1),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _p.weightKg.clamp(40, 130),
                    min: 40,
                    max: 130,
                    onChanged: (v) => _p.updateWeight(v),
                  ),
                ),
              ],
            ),
          ),

          _divider(),

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
                            color: AppColors.text)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(3, (i) {
                    final active = _activityLevel == i;
                    return Expanded(
                      child: Padding(
                        padding:
                        EdgeInsets.only(right: i < 2 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _activityLevel = i),
                          child: AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius:
                              BorderRadius.circular(10),
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
            trailing: Text(
              _p.location.isEmpty ? '—' : _p.location,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

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
            icon: Icons.notifications_active_outlined,
            title: 'Enable reminders',
            subtitle: 'Receive hydration notifications',
            value: _notificationsEnabled,
            onChanged: (v) =>
                setState(() => _notificationsEnabled = v),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.schedule,
            title: 'Reminder frequency',
            trailing: DropdownButton<int>(
              value: _reminderMinutes,
              underline: const SizedBox(),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.text),
              items: const [
                DropdownMenuItem(value: 30,  child: Text('30 min')),
                DropdownMenuItem(value: 60,  child: Text('1 hour')),
                DropdownMenuItem(value: 120, child: Text('2 hours')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _reminderMinutes = v);
              },
            ),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.wb_sunny_outlined,
            title: 'Wake time',
            trailing: _TimePill(
              time: _wakeTime.format(context),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _wakeTime,
                );
                if (picked != null) setState(() => _wakeTime = picked);
              },
            ),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.bedtime_outlined,
            title: 'Sleep time',
            trailing: _TimePill(
              time: _sleepTime.format(context),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _sleepTime,
                );
                if (picked != null) setState(() => _sleepTime = picked);
              },
            ),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.notifications_outlined,
            title: 'Test notification',
            trailing: GestureDetector(
              onTap: NotificationService.showTestNotification,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                      AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text('Send test',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.schedule_outlined,
            title: 'Time format',
            trailing: const Text('24h',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          _divider(),
          _SettingsRow(
            icon: Icons.palette_outlined,
            title: 'Theme',
            trailing: const Text('Light · Blue',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }





  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
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
              style: TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 0.5, color: AppColors.cardBorder);

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

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String   title;
  final Widget   trailing;

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
                    color: AppColors.text)),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData           icon;
  final String             title;
  final String             subtitle;
  final bool               value;
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
                        color: AppColors.text)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
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

class _TimePill extends StatelessWidget {
  final String       time;
  final VoidCallback onTap;

  const _TimePill({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primaryMid.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary)),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined,
                size: 12, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}