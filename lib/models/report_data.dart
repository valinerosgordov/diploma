import 'package:ml_practice/services/auto_tagging_service.dart';
import 'package:ml_practice/services/duplicate_detection_service.dart';
import 'package:ml_practice/services/file_content_classifier_service.dart';
import 'package:ml_practice/services/photo_classifier_service.dart';
import 'package:ml_practice/services/sensitive_data_service.dart';
import 'package:ml_practice/services/threat_assessment_service.dart';

class FileAnalysisResult {
  final ClassificationResult? photo;
  final ContentClassificationResult? content;
  final DuplicateDetectionResult? duplicate;
  final AutoTaggingResult? tags;
  final SensitiveDataResult? sensitiveData;
  final ThreatAssessmentResult? threat;

  const FileAnalysisResult({
    this.photo,
    this.content,
    this.duplicate,
    this.tags,
    this.sensitiveData,
    this.threat,
  });
}

class ReportData {
  final int totalFiles;
  final double totalSize;
  final Map<String, ClassificationResult> photoClassifications;
  final Map<String, ContentClassificationResult> contentClassifications;
  final Map<String, DuplicateDetectionResult> duplicateDetections;
  final Map<String, AutoTaggingResult> autoTags;
  final Map<String, SensitiveDataResult> sensitiveDataFindings;
  final Map<String, ThreatAssessmentResult> threatAssessments;

  const ReportData({
    required this.totalFiles,
    required this.totalSize,
    required this.photoClassifications,
    required this.contentClassifications,
    required this.duplicateDetections,
    required this.autoTags,
    required this.sensitiveDataFindings,
    required this.threatAssessments,
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
    final sensitiveDataFindings = <String, SensitiveDataResult>{};
    final threatAssessments = <String, ThreatAssessmentResult>{};

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
      if (analysis.sensitiveData != null &&
          analysis.sensitiveData!.hasSensitiveData) {
        sensitiveDataFindings[entry.key] = analysis.sensitiveData!;
      }
      if (analysis.threat != null && analysis.threat!.hasThreat) {
        threatAssessments[entry.key] = analysis.threat!;
      }
    }

    return ReportData(
      totalFiles: totalFiles,
      totalSize: totalSize,
      photoClassifications: photoClassifications,
      contentClassifications: contentClassifications,
      duplicateDetections: duplicateDetections,
      autoTags: autoTags,
      sensitiveDataFindings: sensitiveDataFindings,
      threatAssessments: threatAssessments,
    );
  }
}
