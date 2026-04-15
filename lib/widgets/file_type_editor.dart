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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: mappings.length,
      itemBuilder: (context, index) {
        final type = mappings.keys.elementAt(index);
        final extensions = mappings[type]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: ExpansionTile(
            initiallyExpanded: false,
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
              '${extensions.length} extensions',
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: extensions
                          .map(
                            (ext) => Chip(
                              label: Text(ext, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close_rounded, size: 16),
                              onDeleted: () =>
                                  provider.removeExtension(type, ext),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showAddExtensionDialog(context, provider, type),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size(0, 40),
                        ),
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
        title: Text('Add to ${type.toUpperCase()}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Extension (e.g., pdf)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addExtension(type, controller.text);
                Navigator.pop(context);
              }
            },
            child:
                const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
