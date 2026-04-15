import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/providers/file_analysis_provider.dart';
import 'package:ml_practice/widgets/file_type_icon.dart';
import 'package:ml_practice/widgets/analysis_widgets.dart';
import 'package:ml_practice/widgets/security_widgets.dart';
import 'package:ml_practice/widgets/file_type_editor.dart';

class FileListWidget extends StatelessWidget {
  const FileListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileAnalysisProvider>();

    if (provider.isEditingFileTypes) {
      return const FileTypeEditor();
    }

    if (provider.isAnalyzing) {
      return _buildLoadingState(context, provider);
    }

    if (provider.selectedFiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
        child: Column(
          children: [
            // Animated-looking concentric rings
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                  ),
                  // Middle ring
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Inner glow
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      color: AppColors.primaryLight,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ready to analyze',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select files to scan for threats,\nduplicate content, and sensitive data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Feature hints
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FeatureChip(
                    icon: Icons.image_rounded,
                    label: 'ML Classification',
                    color: AppColors.accent),
                const SizedBox(width: 8),
                _FeatureChip(
                    icon: Icons.shield_rounded,
                    label: 'Security Scan',
                    color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FeatureChip(
                    icon: Icons.content_copy_rounded,
                    label: 'Duplicates',
                    color: AppColors.warning),
                const SizedBox(width: 8),
                _FeatureChip(
                    icon: Icons.description_rounded,
                    label: 'Reports',
                    color: AppColors.info),
              ],
            ),
          ],
        ),
      );
    }

    return _buildFileGroups(context, provider);
  }

  Widget _buildLoadingState(
    BuildContext context,
    FileAnalysisProvider provider,
  ) {
    final progress = provider.totalFilesToProcess > 0
        ? provider.processedFiles / provider.totalFilesToProcess
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 40),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 3,
              color: AppColors.primary,
              backgroundColor: AppColors.inputBackground,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${provider.processedFiles} / ${provider.totalFilesToProcess}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Analyzing files...',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: AppColors.inputBackground,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGroups(
    BuildContext context,
    FileAnalysisProvider provider,
  ) {
    final groupedFiles = provider.groupedFiles;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: groupedFiles.length,
      itemBuilder: (context, index) {
        final type = groupedFiles.keys.elementAt(index);
        final files = groupedFiles[type]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: FileTypeIcon(
              path: 'file.$type',
              mappings: provider.fileTypeMappings,
            ),
            title: Text(
              type.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            subtitle: Text(
              '${files.length} file${files.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
              ),
            ),
            iconColor: AppColors.textHint,
            collapsedIconColor: AppColors.textHint,
            shape: const Border(),
            collapsedShape: const Border(),
            children: [
              Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
              ...files.map((file) => _FileCard(file: file, provider: provider)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _FileCard extends StatelessWidget {
  final File file;
  final FileAnalysisProvider provider;

  const _FileCard({required this.file, required this.provider});

  @override
  Widget build(BuildContext context) {
    final analysis = provider.fileAnalysis[file.path];
    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardHover,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: FileTypeIcon(
          path: file.path,
          mappings: provider.fileTypeMappings,
        ),
        title: Text(
          p.basename(file.path),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.fileTypeMappings.getFileType(ext),
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 11,
              ),
            ),
            if (analysis == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Analyzing...',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (analysis.duplicate != null)
                DuplicateIndicatorWidget(result: analysis.duplicate!),
              if (analysis.threat != null)
                ThreatIndicatorWidget(result: analysis.threat!),
            ],
          ],
        ),
        iconColor: AppColors.textHint,
        collapsedIconColor: AppColors.textHint,
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          if (analysis != null) ...[
            if (analysis.photo != null)
              PhotoAnalysisWidget(result: analysis.photo!),
            if (analysis.content != null)
              ContentAnalysisWidget(result: analysis.content!),
            if (analysis.duplicate != null)
              DuplicateAnalysisWidget(result: analysis.duplicate!),
            if (analysis.tags != null)
              TagAnalysisWidget(result: analysis.tags!),
            if (analysis.sensitiveData != null)
              SensitiveDataWidget(result: analysis.sensitiveData!),
            if (analysis.threat != null)
              ThreatAnalysisWidget(result: analysis.threat!),
          ],
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
