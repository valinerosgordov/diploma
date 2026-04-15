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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              // Settings button
              _GlassIconButton(
                icon: provider.isEditingFileTypes
                    ? Icons.done_rounded
                    : Icons.tune_rounded,
                onPressed: provider.toggleEditingFileTypes,
              ),
              const Spacer(),
              // Title
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'File Analysis',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  _GlassIconButton(
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
            ],
          ),
          const SizedBox(height: 16),
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
              decoration: const InputDecoration(
                hintText: 'Search files...',
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textHint, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
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
  final bool isActive;

  const _GlassIconButton({
    required this.icon,
    this.onPressed,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: isActive ? AppColors.textSecondary : AppColors.textHint,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
