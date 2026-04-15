import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/providers/file_analysis_provider.dart';
import 'package:ml_practice/pages/report_history_screen.dart';
import 'package:ml_practice/pages/report_generation_screen.dart';

class HeaderWidget extends StatelessWidget {
  final TextEditingController searchController;

  const HeaderWidget({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileAnalysisProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              // Logo + title
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.security_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    provider.hasAnalysisData
                        ? '${provider.totalFiles} files scanned'
                        : 'Ready to scan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Actions
              _GlassIconButton(
                icon: provider.isEditingFileTypes
                    ? Icons.done_rounded
                    : Icons.tune_rounded,
                onPressed: provider.toggleEditingFileTypes,
              ),
              const SizedBox(width: 8),
              _GlassIconButton(
                icon: Icons.history_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _GradientIconButton(
                icon: Icons.download_rounded,
                isActive: provider.hasAnalysisData,
                onPressed: provider.hasAnalysisData
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportGenerationScreen(
                              reportData: provider.buildReportData(),
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: TextField(
              controller: searchController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Icon(Icons.search_rounded,
                      color: Colors.white, size: 20),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) => provider.setSearchQuery(value),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _GlassIconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.textSecondary),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _GradientIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback? onPressed;

  const _GradientIconButton({
    required this.icon,
    required this.isActive,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive ? null : AppColors.glass,
        borderRadius: BorderRadius.circular(11),
        border: isActive
            ? null
            : Border.all(color: AppColors.border, width: 0.5),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon,
            size: 18,
            color: isActive ? Colors.white : AppColors.textHint),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
