import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
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
    return Icon(_iconForType(type), color: Theme.of(context).colorScheme.primary);
  }

  static IconData _iconForType(String type) {
    return switch (type) {
      'images' => Icons.image,
      'documents' => Icons.description,
      'multimedia' => Icons.play_circle,
      'code' => Icons.code,
      'archives' => Icons.folder_zip,
      'spreadsheets' => Icons.table_chart,
      'presentations' => Icons.slideshow,
      'databases' => Icons.storage,
      'fonts' => Icons.text_fields,
      'system' => Icons.settings_applications,
      _ => Icons.insert_drive_file,
    };
  }
}
