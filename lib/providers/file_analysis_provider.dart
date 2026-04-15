import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:ml_practice/models/file_type_mappings.dart';
import 'package:ml_practice/models/report_data.dart';
import 'package:ml_practice/services/photo_classifier_service.dart';
import 'package:ml_practice/services/file_content_classifier_service.dart';
import 'package:ml_practice/services/duplicate_detection_service.dart';
import 'package:ml_practice/services/auto_tagging_service.dart';

class FileAnalysisProvider extends ChangeNotifier {
  static const int maxFiles = 200;

  final PhotoClassifierService _photoClassifier = PhotoClassifierService();
  final FileContentClassifierService _contentClassifier =
      FileContentClassifierService();
  final DuplicateDetectionService _duplicateDetector =
      DuplicateDetectionService();
  final AutoTaggingService _autoTagger = AutoTaggingService();
  final FileTypeMappings _fileTypeMappings = FileTypeMappings();

  bool _isAnalyzing = false;
  bool _isEditingFileTypes = false;
  bool _isInitialized = false;

  List<File> _selectedFiles = [];
  Map<String, double> _fileDistribution = {};
  Map<String, FileAnalysisResult> _fileAnalysis = {};

  int _totalFiles = 0;
  double _totalSize = 0;
  int _categories = 0;
  int _processedFiles = 0;
  int _totalFilesToProcess = 0;

  String _searchQuery = '';
  final List<String> _warnings = [];

  // Getters
  bool get isAnalyzing => _isAnalyzing;
  bool get isEditingFileTypes => _isEditingFileTypes;
  bool get isInitialized => _isInitialized;
  List<File> get selectedFiles => _selectedFiles;
  Map<String, double> get fileDistribution => _fileDistribution;
  Map<String, FileAnalysisResult> get fileAnalysis => _fileAnalysis;
  int get totalFiles => _totalFiles;
  double get totalSize => _totalSize;
  int get categories => _categories;
  int get processedFiles => _processedFiles;
  int get totalFilesToProcess => _totalFilesToProcess;
  String get searchQuery => _searchQuery;
  FileTypeMappings get fileTypeMappings => _fileTypeMappings;
  List<String> get warnings => List.unmodifiable(_warnings);

  bool get hasAnalysisData => _fileAnalysis.isNotEmpty;
  bool get hasWarnings => _warnings.isNotEmpty;

  List<File> get filteredFiles {
    if (_searchQuery.isEmpty) return _selectedFiles;
    return _selectedFiles
        .where((file) => file.path.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Map<String, List<File>> get groupedFiles {
    final grouped = <String, List<File>>{};
    for (final file in filteredFiles) {
      final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      final type = _fileTypeMappings.getFileType(ext);
      grouped.putIfAbsent(type, () => []).add(file);
    }
    return grouped;
  }

  ReportData buildReportData() {
    return ReportData.fromAnalysis(
      totalFiles: _totalFiles,
      totalSize: _totalSize,
      fileAnalysis: _fileAnalysis,
    );
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _photoClassifier.initialize();
    await _contentClassifier.initialize();
    await _duplicateDetector.initialize();
    await _autoTagger.initialize();
    _isInitialized = true;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void toggleEditingFileTypes() {
    _isEditingFileTypes = !_isEditingFileTypes;
    notifyListeners();
  }

  void addExtension(String type, String extension) {
    _fileTypeMappings.addExtension(type, extension);
    notifyListeners();
  }

  void removeExtension(String type, String extension) {
    _fileTypeMappings.removeExtension(type, extension);
    notifyListeners();
  }

  Future<void> analyzeDirectory() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowCompression: false,
      );

      if (result == null) return;

      var files = result.files.where((f) => f.path != null).toList();
      if (files.length > maxFiles) {
        files = files.take(maxFiles).toList();
      }
      _isAnalyzing = true;
      _fileAnalysis.clear();
      _selectedFiles.clear();
      _fileDistribution.clear();
      _warnings.clear();
      _processedFiles = 0;
      _totalFilesToProcess = files.length;

      if (result.files.length > maxFiles) {
        _warnings.add(
          'Selected ${result.files.length} files, limited to $maxFiles.',
        );
      }
      notifyListeners();

      const batchSize = 3;
      final typeCounts = <String, int>{};
      double totalSize = 0;
      final categoriesSet = <String>{};

      for (var i = 0; i < files.length; i += batchSize) {
        final batch = files.skip(i).take(batchSize).toList();

        // Process files sequentially within batch to avoid race condition
        for (final file in batch) {
          final fileEntity = File(file.path!);
          _selectedFiles.add(fileEntity);

          final ext =
              p.extension(file.path!).replaceFirst('.', '').toLowerCase();
          final type = _fileTypeMappings.getFileType(ext);

          await _analyzeFile(fileEntity, type);

          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
          totalSize += file.size;
          categoriesSet.add(type);

          _processedFiles++;
        }

        _fileDistribution = typeCounts.map(
          (k, v) => MapEntry(k, v.toDouble()),
        );
        _totalFiles = _selectedFiles.length;
        _totalSize = totalSize / (1024 * 1024);
        _categories = categoriesSet.length;
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 50));
      }
    } catch (e) {
      debugPrint('Error analyzing directory: $e');
      rethrow;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> _analyzeFile(File file, String type) async {
    try {
      ClassificationResult? photo;
      ContentClassificationResult? content;
      AutoTaggingResult? tags;

      if (type == 'images') {
        photo = await _photoClassifier.classifyImage(file);
        tags = await _autoTagger.generateTags(file);
      } else if (type == 'documents' || type == 'others') {
        content = await _contentClassifier.classifyContent(file);
      }

      final duplicate = await _duplicateDetector.checkForDuplicate(file);

      _fileAnalysis[file.path] = FileAnalysisResult(
        photo: photo,
        content: content,
        duplicate: duplicate,
        tags: tags,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error analyzing file ${file.path}: $e');
      _warnings.add('Failed to analyze ${p.basename(file.path)}: $e');
    }
  }

  @override
  void dispose() {
    _photoClassifier.dispose();
    _contentClassifier.dispose();
    _duplicateDetector.dispose();
    _autoTagger.dispose();
    super.dispose();
  }
}
