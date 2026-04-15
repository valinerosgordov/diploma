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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  provider.isEditingFileTypes ? Icons.done : Icons.settings,
                  color: AppColors.textSecondary,
                ),
                onPressed: provider.toggleEditingFileTypes,
              ),
              const Text(
                'File Analysis Tool',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history,
                        color: AppColors.textSecondary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportHistoryScreen(),
                        ),
                      );
                    },
                    tooltip: 'Report History',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.file_download_outlined,
                      color: provider.hasAnalysisData
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
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
                    tooltip: 'Generate Report',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search files...',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => provider.setSearchQuery(value),
          ),
        ],
      ),
    );
  }
}
