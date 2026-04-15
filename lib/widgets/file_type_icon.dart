import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/models/file_type_mappings.dart';

class FileTypeIcon extends StatelessWidget {
  final String path;
  final FileTypeMappings mappings;

  const FileTypeIcon({
    super.key,
    required this.path,
    required this.mappings,
  });

  @override
  Widget build(BuildContext context) {
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    final type = mappings.getFileType(ext);
    final color = _colorForType(type);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_iconForType(type), color: color, size: 18),
    );
  }

  static Color _colorForType(String type) {
    return switch (type) {
      'images' => AppColors.accent,
      'documents' => AppColors.primary,
      'multimedia' => const Color(0xFFE17055),
      'code' => AppColors.success,
      'archives' => AppColors.warning,
      'spreadsheets' => const Color(0xFF00B894),
      'presentations' => const Color(0xFFA29BFE),
      'databases' => AppColors.info,
      'fonts' => AppColors.textSecondary,
      'system' => AppColors.error,
      _ => AppColors.textHint,
    };
  }

  static IconData _iconForType(String type) {
    return switch (type) {
      'images' => Icons.image_rounded,
      'documents' => Icons.description_rounded,
      'multimedia' => Icons.play_circle_rounded,
      'code' => Icons.code_rounded,
      'archives' => Icons.folder_zip_rounded,
      'spreadsheets' => Icons.table_chart_rounded,
      'presentations' => Icons.slideshow_rounded,
      'databases' => Icons.storage_rounded,
      'fonts' => Icons.text_fields_rounded,
      'system' => Icons.settings_applications_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }
}
