import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../theme/app_colors.dart';

class ReminderRow extends StatelessWidget {
  final Reminder reminder;

  const ReminderRow({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final String statusText;
    final IconData statusIcon;

    switch (reminder.status) {
      case ReminderStatus.upcoming:
        dotColor   = AppColors.primary;
        statusText = 'Upcoming';
        statusIcon = Icons.schedule;
        break;
      case ReminderStatus.completed:
        dotColor   = AppColors.successGreen;
        statusText = 'Completed';
        statusIcon = Icons.check_circle_outline;
        break;
      case ReminderStatus.skipped:
        dotColor   = AppColors.textLight;
        statusText = 'Skipped';
        statusIcon = Icons.remove_circle_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const Icon(Icons.water_drop_outlined,
              color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drink ${reminder.amountMl} ml of water',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: reminder.status == ReminderStatus.skipped
                        ? AppColors.textMuted
                        : AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(statusIcon, size: 11, color: dotColor),
                    const SizedBox(width: 3),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: dotColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            reminder.time,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}