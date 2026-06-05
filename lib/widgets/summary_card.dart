import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final Color? bgColor;
  final VoidCallback? onTap;
  final String? subtitle;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.bgColor,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final bg = bgColor ?? c.withOpacity(0.1);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: c.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: c, size: 22),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
