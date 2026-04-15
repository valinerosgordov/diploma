import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/providers/file_analysis_provider.dart';
import 'package:ml_practice/widgets/file_type_icon.dart';
import 'package:ml_practice/widgets/analysis_widgets.dart';
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No files analyzed yet',
            style: TextStyle(color: AppColors.textHint, fontSize: 16),
          ),
        ),
      );
    }

    return _buildFileGroups(context, provider);
  }

  Widget _buildLoadingState(
    BuildContext context,
    FileAnalysisProvider provider,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Processing files: ${provider.processedFiles} / ${provider.totalFilesToProcess}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (provider.processedFiles > 0 && provider.totalFilesToProcess > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LinearProgressIndicator(
                value: provider.processedFiles / provider.totalFilesToProcess,
                backgroundColor: AppColors.inputBackground,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
      padding: const EdgeInsets.all(16),
      itemCount: groupedFiles.length,
      itemBuilder: (context, index) {
        final type = groupedFiles.keys.elementAt(index);
        final files = groupedFiles[type]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: FileTypeIcon(
              path: 'file.$type',
              mappings: provider.fileTypeMappings,
            ),
            title: Text(
              type.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '${files.length} file${files.length == 1 ? '' : 's'}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            iconColor: AppColors.textSecondary,
            collapsedIconColor: AppColors.textSecondary,
            backgroundColor: AppColors.card,
            collapsedBackgroundColor: AppColors.card,
            children: [
              Column(
                children: files.map((file) {
                  return _FileCard(file: file, provider: provider);
                }).toList(),
              ),
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: AppColors.cardHover,
      child: ExpansionTile(
        leading: FileTypeIcon(
          path: file.path,
          mappings: provider.fileTypeMappings,
        ),
        title: Text(
          p.basename(file.path),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.fileTypeMappings.getFileType(ext),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (analysis == null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Analyzing...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              )
            else if (analysis.duplicate != null)
              DuplicateIndicatorWidget(result: analysis.duplicate!),
          ],
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        backgroundColor: AppColors.cardHover,
        collapsedBackgroundColor: AppColors.cardHover,
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
          ],
        ],
      ),
    );
  }
}
