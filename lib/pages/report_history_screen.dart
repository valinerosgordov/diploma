import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ml_practice/models/report_history.dart';
import 'package:ml_practice/services/report_history_service.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final ReportHistoryService _historyService = ReportHistoryService();
  List<ReportHistory> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _historyService.getReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport(ReportHistory report) async {
    try {
      final file = File(report.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _historyService.deleteReport(report.filePath);
      await _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting report: $e')),
        );
      }
    }
  }

  Future<void> _openReport(ReportHistory report) async {
    try {
      final file = File(report.filePath);
      if (await file.exists()) {
        await OpenFile.open(report.filePath);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report file not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report History'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: _loadReports,
              padding: EdgeInsets.zero,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.history_rounded,
                            color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No reports yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _reports.length,
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    final isPdf = report.fileType == 'pdf';
                    final color =
                        isPdf ? AppColors.error : const Color(0xFF00B894);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.table_chart_rounded,
                            color: color,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          report.fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, y  HH:mm')
                                  .format(report.generatedAt),
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${report.totalFiles} files analyzed',
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(
                              icon: Icons.open_in_new_rounded,
                              color: AppColors.accent,
                              onPressed: () => _openReport(report),
                            ),
                            const SizedBox(width: 6),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              color: AppColors.error,
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Report'),
                                  content: const Text(
                                    'Delete this report permanently?',
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel',
                                          style: TextStyle(
                                              color: AppColors.textSecondary)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteReport(report);
                                      },
                                      child: const Text('Delete',
                                          style: TextStyle(
                                              color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
