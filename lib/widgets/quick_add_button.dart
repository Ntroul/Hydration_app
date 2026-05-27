import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class QuickAddButton extends StatelessWidget {
  final IconData icon;
  final double amount;
  final String label;
  final VoidCallback onTap;

  const QuickAddButton({
    super.key,
    required this.icon,
    required this.amount,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(height: 7),
            Text(
              '${amount.round()} ml',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}