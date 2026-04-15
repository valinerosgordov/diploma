import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/providers/file_analysis_provider.dart';
import 'package:ml_practice/widgets/file_type_icon.dart';

class FileTypeEditor extends StatelessWidget {
  const FileTypeEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileAnalysisProvider>();
    final mappings = provider.fileTypeMappings.mappings;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: mappings.length,
      itemBuilder: (context, index) {
        final type = mappings.keys.elementAt(index);
        final extensions = mappings[type]!;

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
              '${extensions.length} extension${extensions.length == 1 ? '' : 's'}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            iconColor: AppColors.textSecondary,
            collapsedIconColor: AppColors.textSecondary,
            backgroundColor: AppColors.card,
            collapsedBackgroundColor: AppColors.card,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: extensions
                          .map(
                            (ext) => Chip(
                              label: Text(ext),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () =>
                                  provider.removeExtension(type, ext),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showAddExtensionDialog(context, provider, type),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Extension'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddExtensionDialog(
    BuildContext context,
    FileAnalysisProvider provider,
    String type,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Extension to ${type.toUpperCase()}'),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter file extension (e.g., pdf)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addExtension(type, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
