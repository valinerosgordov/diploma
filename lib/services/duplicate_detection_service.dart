import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ml_practice/models/file_type_mappings.dart';

enum MatchType {
  exactBinaryMatch('exact_binary_match'),
  contentSimilarity('content_similarity'),
  noMatch('no_match'),
  error('error');

  final String value;
  const MatchType(this.value);

  @override
  String toString() => value;
}

class DuplicateDetectionResult {
  final bool isDuplicate;
  final double similarityScore;
  final MatchType matchType;
  final String? matchedWith;

  const DuplicateDetectionResult({
    required this.isDuplicate,
    required this.similarityScore,
    required this.matchType,
    this.matchedWith,
  });
}

class DuplicateDetectionService {
  static const int _maxTextLengthForComparison = 10000;
  static const int _levenshteinThreshold = 2000;
  static const double _similarityThreshold = 0.8;

  final TextRecognizer _textRecognizer = TextRecognizer();
  final Map<String, String> _fileHashes = {};
  final Map<String, String> _fileContents = {};

  Future<void> initialize() async {}

  Future<DuplicateDetectionResult> checkForDuplicate(File file) async {
    try {
      final fileHash = await _calculateFileHash(file);

      // Exact binary match
      if (_fileHashes.containsValue(fileHash)) {
        final matchedFile = _fileHashes.entries
            .firstWhere((entry) => entry.value == fileHash)
            .key;

        return DuplicateDetectionResult(
          isDuplicate: true,
          similarityScore: 1.0,
          matchType: MatchType.exactBinaryMatch,
          matchedWith: matchedFile,
        );
      }

      // Content similarity for text files
      if (FileTypeMappings.isTextFile(file.path)) {
        var content = await _extractTextContent(file);

        // Truncate to prevent OOM
        if (content.length > _maxTextLengthForComparison) {
          content = content.substring(0, _maxTextLengthForComparison);
        }

        double highestSimilarity = 0.0;
        String? mostSimilarFile;

        for (final entry in _fileContents.entries) {
          final similarity = _calculateSimilarity(content, entry.value);
          if (similarity > highestSimilarity) {
            highestSimilarity = similarity;
            mostSimilarFile = entry.key;
          }
        }

        if (highestSimilarity > _similarityThreshold) {
          return DuplicateDetectionResult(
            isDuplicate: true,
            similarityScore: highestSimilarity,
            matchType: MatchType.contentSimilarity,
            matchedWith: mostSimilarFile,
          );
        }

        _fileContents[file.path] = content;
      }

      _fileHashes[file.path] = fileHash;

      return const DuplicateDetectionResult(
        isDuplicate: false,
        similarityScore: 0.0,
        matchType: MatchType.noMatch,
      );
    } catch (e) {
      debugPrint('Error checking for duplicate: $e');
      return const DuplicateDetectionResult(
        isDuplicate: false,
        similarityScore: 0.0,
        matchType: MatchType.error,
      );
    }
  }

  /// Stream-based SHA-256 hash — no full file in memory
  Future<String> _calculateFileHash(File file) async {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }

    input.close();
    return output.events.single.toString();
  }

  Future<String> _extractTextContent(File file) async {
    try {
      if (FileTypeMappings.isImageFile(file.path)) {
        final inputImage = InputImage.fromFile(file);
        final recognizedText =
            await _textRecognizer.processImage(inputImage);
        return recognizedText.text.toLowerCase();
      } else {
        final content = await file.readAsString();
        return content.toLowerCase();
      }
    } catch (e) {
      debugPrint('Error extracting text content: $e');
      return '';
    }
  }

  /// Pick algorithm based on text length:
  /// - Short texts: Levenshtein (accurate)
  /// - Long texts: Trigram similarity (O(n) memory)
  double _calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    final maxLen = max(text1.length, text2.length);

    if (maxLen <= _levenshteinThreshold) {
      return _levenshteinSimilarity(text1, text2);
    }

    return _trigramSimilarity(text1, text2);
  }

  double _levenshteinSimilarity(String text1, String text2) {
    final distance = _levenshteinDistance(text1, text2);
    return 1 - (distance / max(text1.length, text2.length));
  }

  /// Optimized Levenshtein — single row instead of full matrix: O(min(n,m)) memory
  int _levenshteinDistance(String s1, String s2) {
    // Ensure s1 is shorter for memory efficiency
    if (s1.length > s2.length) {
      final temp = s1;
      s1 = s2;
      s2 = temp;
    }

    final len1 = s1.length;
    final len2 = s2.length;

    var prev = List<int>.generate(len1 + 1, (i) => i);
    var curr = List<int>.filled(len1 + 1, 0);

    for (int j = 1; j <= len2; j++) {
      curr[0] = j;
      for (int i = 1; i <= len1; i++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        curr[i] = min(
          min(curr[i - 1] + 1, prev[i] + 1),
          prev[i - 1] + cost,
        );
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[len1];
  }

  /// Trigram (3-gram) similarity — O(n) memory, good for long texts
  double _trigramSimilarity(String text1, String text2) {
    final trigrams1 = _extractTrigrams(text1);
    final trigrams2 = _extractTrigrams(text2);

    if (trigrams1.isEmpty || trigrams2.isEmpty) return 0.0;

    final intersection = trigrams1.intersection(trigrams2).length;
    final union = trigrams1.union(trigrams2).length;

    return intersection / union; // Jaccard similarity
  }

  Set<String> _extractTrigrams(String text) {
    if (text.length < 3) return {text};
    final trigrams = <String>{};
    for (int i = 0; i <= text.length - 3; i++) {
      trigrams.add(text.substring(i, i + 3));
    }
    return trigrams;
  }

  void clearCache() {
    _fileHashes.clear();
    _fileContents.clear();
  }

  void dispose() {
    _textRecognizer.close();
    clearCache();
  }
}
