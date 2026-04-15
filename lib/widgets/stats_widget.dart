import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/providers/file_analysis_provider.dart';

class StatsWidget extends StatelessWidget {
  const StatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileAnalysisProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.folder_rounded,
            value: provider.totalFiles.toString(),
            label: 'Files',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.storage_rounded,
            value: '${provider.totalSize.toStringAsFixed(1)}',
            label: 'MB',
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          _StatCard(
            icon: Icons.category_rounded,
            value: provider.categories.toString(),
            label: 'Types',
            color: AppColors.warning,
          ),
          if (provider.securityIssueCount > 0) ...[
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.shield_rounded,
              value: provider.securityIssueCount.toString(),
              label: 'Issues',
              color: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
