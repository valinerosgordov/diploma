import 'package:flutter_test/flutter_test.dart';
import 'package:ml_practice/models/report_data.dart';
import 'package:ml_practice/services/photo_classifier_service.dart';
import 'package:ml_practice/services/file_content_classifier_service.dart';
import 'package:ml_practice/services/duplicate_detection_service.dart';
import 'package:ml_practice/services/auto_tagging_service.dart';

void main() {
  group('ReportData.fromAnalysis', () {
    test('correctly separates analysis results by type', () {
      final fileAnalysis = <String, FileAnalysisResult>{
        '/path/image.jpg': FileAnalysisResult(
          photo: ClassificationResult(
            category: 'nature',
            mlLabels: ['tree', 'sky'],
            confidences: [0.9, 0.8],
          ),
          tags: AutoTaggingResult(
            tags: ['landscape'],
            confidences: [0.85],
          ),
          duplicate: const DuplicateDetectionResult(
            isDuplicate: false,
            similarityScore: 0.0,
            matchType: MatchType.noMatch,
          ),
        ),
        '/path/doc.txt': FileAnalysisResult(
          content: ContentClassificationResult(
            contentType: 'source_code',
            confidenceScores: {'source_code': 0.8},
            detectedKeywords: ['import', 'class'],
          ),
          duplicate: const DuplicateDetectionResult(
            isDuplicate: false,
            similarityScore: 0.0,
            matchType: MatchType.noMatch,
          ),
        ),
      };

      final report = ReportData.fromAnalysis(
        totalFiles: 2,
        totalSize: 1.5,
        fileAnalysis: fileAnalysis,
      );

      expect(report.totalFiles, 2);
      expect(report.totalSize, 1.5);
      expect(report.photoClassifications.length, 1);
      expect(report.contentClassifications.length, 1);
      expect(report.duplicateDetections.length, 2);
      expect(report.autoTags.length, 1);

      expect(
        report.photoClassifications['/path/image.jpg']!.category,
        'nature',
      );
      expect(
        report.contentClassifications['/path/doc.txt']!.contentType,
        'source_code',
      );
    });

    test('handles empty analysis', () {
      final report = ReportData.fromAnalysis(
        totalFiles: 0,
        totalSize: 0,
        fileAnalysis: {},
      );

      expect(report.totalFiles, 0);
      expect(report.photoClassifications, isEmpty);
      expect(report.contentClassifications, isEmpty);
      expect(report.duplicateDetections, isEmpty);
      expect(report.autoTags, isEmpty);
    });
  });

  group('FileAnalysisResult', () {
    test('all fields nullable', () {
      const result = FileAnalysisResult();
      expect(result.photo, isNull);
      expect(result.content, isNull);
      expect(result.duplicate, isNull);
      expect(result.tags, isNull);
    });
  });

  group('MatchType', () {
    test('toString returns expected value', () {
      expect(MatchType.exactBinaryMatch.toString(), 'exact_binary_match');
      expect(MatchType.contentSimilarity.toString(), 'content_similarity');
      expect(MatchType.noMatch.toString(), 'no_match');
      expect(MatchType.error.toString(), 'error');
    });
  });
}
