import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/providers/file_analysis_provider.dart';
import 'package:ml_practice/widgets/header_widget.dart';
import 'package:ml_practice/widgets/stats_widget.dart';
import 'package:ml_practice/widgets/distribution_chart.dart';
import 'package:ml_practice/widgets/file_list_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showWarnings(BuildContext context, FileAnalysisProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Analysis Warnings'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: provider.warnings
                .map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber,
                              color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(w,
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileAnalysisProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                HeaderWidget(searchController: _searchController),
                const SizedBox(height: 8),
                const StatsWidget(),
                const SizedBox(height: 16),
                const DistributionChart(),
                const FileListWidget(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: provider.isAnalyzing
              ? null
              : () async {
                  try {
                    await provider.analyzeDirectory();
                    if (context.mounted && provider.hasWarnings) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${provider.warnings.length} warning(s) during analysis',
                          ),
                          action: SnackBarAction(
                            label: 'Details',
                            onPressed: () => _showWarnings(context, provider),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error analyzing directory: $e')),
                      );
                    }
                  }
                },
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          icon: const Icon(Icons.radar, size: 22),
          label: const Text(
            'Analyze',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
