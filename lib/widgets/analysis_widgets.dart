import 'package:flutter/material.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/services/photo_classifier_service.dart';
import 'package:ml_practice/services/file_content_classifier_service.dart';
import 'package:ml_practice/services/duplicate_detection_service.dart';
import 'package:ml_practice/services/auto_tagging_service.dart';

class PhotoAnalysisWidget extends StatelessWidget {
  final ClassificationResult result;

  const PhotoAnalysisWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photo Classification:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            result.mlLabels.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${result.mlLabels[i]} (${(result.confidences[i] * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContentAnalysisWidget extends StatelessWidget {
  final ContentClassificationResult result;

  const ContentAnalysisWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Analysis:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${result.contentType}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keywords:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Wrap(
            spacing: 8,
            children: result.detectedKeywords
                .map((keyword) => Chip(label: Text(keyword)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DuplicateIndicatorWidget extends StatelessWidget {
  final DuplicateDetectionResult result;

  const DuplicateIndicatorWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            result.isDuplicate ? Icons.warning : Icons.check_circle,
            color: result.isDuplicate ? AppColors.error : AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            result.isDuplicate ? 'Duplicate' : 'Unique',
            style: TextStyle(
              color: result.isDuplicate ? AppColors.error : AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class DuplicateAnalysisWidget extends StatelessWidget {
  final DuplicateDetectionResult result;

  const DuplicateAnalysisWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.isDuplicate ? Icons.warning : Icons.check_circle,
                color: result.isDuplicate ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 8),
              Text(
                result.isDuplicate
                    ? 'Duplicate Detected'
                    : 'No Duplicates Found',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (result.isDuplicate) ...[
            const SizedBox(height: 8),
            Text(
              'Matched with: ${result.matchedWith}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              'Similarity: ${(result.similarityScore * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class TagAnalysisWidget extends StatelessWidget {
  final AutoTaggingResult result;

  const TagAnalysisWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Auto-generated Tags:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              result.tags.length,
              (i) => Chip(
                label: Text(result.tags[i]),
                avatar: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '${(result.confidences[i] * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
