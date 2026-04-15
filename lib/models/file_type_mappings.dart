class FileTypeMappings {
  Map<String, Set<String>> _mappings;

  FileTypeMappings()
      : _mappings = {
          'images': {
            'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'tiff', 'ico',
            'raw',
          },
          'documents': {
            'pdf', 'doc', 'docx', 'txt', 'rtf', 'odt', 'epub', 'md', 'tex',
          },
          'multimedia': {
            'mp3', 'mp4', 'wav', 'avi', 'mov', 'mkv', 'flv', 'wmv', 'webm',
            'm4a', 'm4v',
          },
          'code': {
            'js', 'py', 'java', 'cpp', 'cs', 'html', 'css', 'php', 'rb',
            'swift', 'kt', 'dart', 'go',
          },
          'archives': {'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'iso'},
          'spreadsheets': {'xls', 'xlsx', 'csv', 'ods', 'numbers'},
          'presentations': {'ppt', 'pptx', 'key', 'odp'},
          'databases': {'sql', 'db', 'sqlite', 'mdb', 'accdb'},
          'fonts': {'ttf', 'otf', 'woff', 'woff2', 'eot'},
          'system': {
            'exe', 'dll', 'sys', 'bat', 'sh', 'app', 'dmg', 'deb', 'rpm',
          },
        };

  static const textExtensions = [
    '.txt', '.md', '.json', '.xml', '.csv', '.yaml', '.yml',
    '.dart', '.java', '.kt', '.py', '.js', '.ts', '.html', '.css',
    '.c', '.cpp', '.h', '.hpp', '.rs', '.go', '.rb', '.php',
    '.properties', '.conf', '.config', '.ini', '.log',
  ];

  static const imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp',
    '.heic', '.heif', '.tiff', '.tif',
  ];

  static const pdfExtensions = ['.pdf'];

  static bool isTextFile(String path) {
    final lower = path.toLowerCase();
    return textExtensions.any((ext) => lower.endsWith(ext));
  }

  static bool isImageFile(String path) {
    final lower = path.toLowerCase();
    return imageExtensions.any((ext) => lower.endsWith(ext));
  }

  static bool isPdfFile(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  Map<String, Set<String>> get mappings => _mappings;

  String getFileType(String extension) {
    for (final entry in _mappings.entries) {
      if (entry.value.contains(extension.toLowerCase())) {
        return entry.key;
      }
    }
    return 'others';
  }

  void addExtension(String type, String extension) {
    if (_mappings.containsKey(type)) {
      _mappings[type] = {..._mappings[type]!, extension.toLowerCase()};
    }
  }

  void removeExtension(String type, String extension) {
    _mappings[type]?.remove(extension);
  }
}
