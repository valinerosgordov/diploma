import 'package:ml_practice/services/auto_tagging_service.dart';
import 'package:ml_practice/services/duplicate_detection_service.dart';
import 'package:ml_practice/services/file_content_classifier_service.dart';
import 'package:ml_practice/services/photo_classifier_service.dart';

class FileAnalysisResult {
  final ClassificationResult? photo;
  final ContentClassificationResult? content;
  final DuplicateDetectionResult? duplicate;
  final AutoTaggingResult? tags;

  const FileAnalysisResult({
    this.photo,
    this.content,
    this.duplicate,
    this.tags,
  });
}

class ReportData {
  final int totalFiles;
  final double totalSize;
  final Map<String, ClassificationResult> photoClassifications;
  final Map<String, ContentClassificationResult> contentClassifications;
  final Map<String, DuplicateDetectionResult> duplicateDetections;
  final Map<String, AutoTaggingResult> autoTags;

  const ReportData({
    required this.totalFiles,
    required this.totalSize,
    required this.photoClassifications,
    required this.contentClassifications,
    required this.duplicateDetections,
    required this.autoTags,
  });

  factory ReportData.fromAnalysis({
    required int totalFiles,
    required double totalSize,
    required Map<String, FileAnalysisResult> fileAnalysis,
  }) {
    final photoClassifications = <String, ClassificationResult>{};
    final contentClassifications = <String, ContentClassificationResult>{};
    final duplicateDetections = <String, DuplicateDetectionResult>{};
    final autoTags = <String, AutoTaggingResult>{};

    for (final entry in fileAnalysis.entries) {
      final analysis = entry.value;
      if (analysis.photo != null) {
        photoClassifications[entry.key] = analysis.photo!;
      }
      if (analysis.content != null) {
        contentClassifications[entry.key] = analysis.content!;
      }
      if (analysis.duplicate != null) {
        duplicateDetections[entry.key] = analysis.duplicate!;
      }
      if (analysis.tags != null) {
        autoTags[entry.key] = analysis.tags!;
      }
    }

    return ReportData(
      totalFiles: totalFiles,
      totalSize: totalSize,
      photoClassifications: photoClassifications,
      contentClassifications: contentClassifications,
      duplicateDetections: duplicateDetections,
      autoTags: autoTags,
    );
  }
}
