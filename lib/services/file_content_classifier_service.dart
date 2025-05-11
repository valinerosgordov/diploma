import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ContentClassificationResult {
  final String contentType;
  final Map<String, double> confidenceScores;
  final List<String> detectedKeywords;

  ContentClassificationResult({
    required this.contentType,
    required this.confidenceScores,
    required this.detectedKeywords,
  });
}

class FileContentClassifierService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Initialize the service
  Future<void> initialize() async {
    // No initialization needed for ML Kit
  }

  /// Classify file content into predefined categories
  Future<ContentClassificationResult> classifyContent(File file) async {
    try {
      // Extract text content based on file type
      final String content = await _extractTextContent(file);

      if (content.isEmpty) {
        return ContentClassificationResult(
          contentType: 'unknown',
          confidenceScores: {},
          detectedKeywords: [],
        );
      }

      // Calculate confidence scores for each content type
      Map<String, double> confidenceScores =
          _calculateContentTypeScores(content);

      // Determine the primary content type based on highest confidence score
      String contentType = _determineContentType(confidenceScores);

      // Extract relevant keywords
      List<String> detectedKeywords = _extractKeywords(content);

      return ContentClassificationResult(
        contentType: contentType,
        confidenceScores: confidenceScores,
        detectedKeywords: detectedKeywords,
      );
    } catch (e) {
      print('Error classifying file content: $e');
      return ContentClassificationResult(
        contentType: 'unknown',
        confidenceScores: {},
        detectedKeywords: [],
      );
    }
  }

  /// Extract text content from file based on its type
  Future<String> _extractTextContent(File file) async {
    try {
      final String path = file.path.toLowerCase();

      if (_isPdfFile(path)) {
        // For PDF files
        try {
          final Uint8List bytes = await file.readAsBytes();
          final PdfDocument doc = PdfDocument(inputBytes: bytes);
          String text = '';

          // Extract text from all pages
          for (int i = 0; i < doc.pages.count; i++) {
            final PdfTextExtractor extractor = PdfTextExtractor(doc);
            text += await extractor.extractText(startPageIndex: i) + '\n';
          }

          doc.dispose();
          return text.toLowerCase();
        } catch (e) {
          print('Error extracting PDF text: $e');
          return '';
        }
      } else if (_isImageFile(path)) {
        // For image files, use ML Kit text recognition
        try {
          final inputImage = InputImage.fromFile(file);
          final RecognizedText recognizedText =
              await _textRecognizer.processImage(inputImage);
          return recognizedText.text.toLowerCase();
        } catch (e) {
          print('Error extracting image text: $e');
          return '';
        }
      } else if (_isTextFile(path)) {
        // For text files, read directly
        try {
          String content = await file.readAsString();
          return content.toLowerCase();
        } catch (e) {
          print('Error reading text file: $e');
          return '';
        }
      }

      return '';
    } catch (e) {
      print('Error extracting text content: $e');
      return '';
    }
  }

  /// Calculate confidence scores for different content types
  Map<String, double> _calculateContentTypeScores(String content) {
    Map<String, double> scores = {
      'source_code': _calculateSourceCodeScore(content),
      'documentation': _calculateDocumentationScore(content),
      'configuration': _calculateConfigurationScore(content),
      'data': _calculateDataScore(content),
    };

    // Normalize scores
    double total = scores.values.fold(0, (sum, score) => sum + score);
    if (total > 0) {
      scores.forEach((key, value) {
        scores[key] = value / total;
      });
    }

    return scores;
  }

  double _calculateSourceCodeScore(String content) {
    final List<String> codeIndicators = [
      'class ',
      'function ',
      'def ',
      'import ',
      'return ',
      'public ',
      'private ',
      'const ',
      'var ',
      'let ',
      'if ',
      'for ',
      'while ',
      '{',
      '}',
      ';',
      'package ',
      'namespace ',
      'interface ',
      'extends ',
      'implements '
    ];

    return _calculateIndicatorPresence(content, codeIndicators);
  }

  double _calculateDocumentationScore(String content) {
    final List<String> docIndicators = [
      'introduction',
      'overview',
      'description',
      'guide',
      'manual',
      'documentation',
      'instructions',
      'readme',
      'how to',
      'usage',
      'example',
      'chapter',
      'section',
      'reference',
      'appendix',
      'table of contents',
      'summary',
      'conclusion'
    ];

    return _calculateIndicatorPresence(content, docIndicators);
  }

  double _calculateConfigurationScore(String content) {
    final List<String> configIndicators = [
      'config',
      'settings',
      'environment',
      'properties',
      'api_key',
      'password',
      'username',
      'host',
      'port',
      'database',
      'url',
      'endpoint',
      'server',
      'client',
      'debug',
      'production',
      'development',
      'test'
    ];

    return _calculateIndicatorPresence(content, configIndicators);
  }

  double _calculateDataScore(String content) {
    final List<String> dataIndicators = [
      'data',
      'json',
      'xml',
      'csv',
      'array',
      'list',
      'table',
      'record',
      'field',
      'value',
      'key',
      'object',
      'schema',
      'database',
      'query',
      'select',
      'insert',
      'update'
    ];

    return _calculateIndicatorPresence(content, dataIndicators);
  }

  double _calculateIndicatorPresence(String content, List<String> indicators) {
    int matches = 0;
    int totalWeight = 0;

    for (String indicator in indicators) {
      // Count all occurrences of each indicator
      RegExp regex = RegExp(indicator, caseSensitive: false);
      int count = regex.allMatches(content).length;
      if (count > 0) {
        matches += count;
        totalWeight++;
      }
    }

    // Consider both the variety of indicators and their frequency
    if (totalWeight == 0) return 0.0;
    double varietyScore = totalWeight / indicators.length;
    double frequencyScore =
        matches / (content.length / 100); // Normalize by content length

    return (varietyScore + frequencyScore) / 2;
  }

  String _determineContentType(Map<String, double> scores) {
    if (scores.isEmpty) return 'unknown';

    var maxEntry = scores.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Require a minimum confidence threshold
    return maxEntry.value > 0.15 ? maxEntry.key : 'unknown';
  }

  List<String> _extractKeywords(String content) {
    final Map<String, int> wordFrequency = {};
    final RegExp wordPattern = RegExp(r'\b\w+\b');

    // Extract words and count their frequency
    final matches = wordPattern.allMatches(content);
    for (var match in matches) {
      String word = match.group(0)!.toLowerCase();
      if (_isRelevantKeyword(word)) {
        wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
      }
    }

    // Sort by frequency and return top keywords
    final sortedWords = wordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(15).map((e) => e.key).toList();
  }

  bool _isRelevantKeyword(String word) {
    final List<String> commonWords = [
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'as',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'should',
      'could',
      'may',
      'might',
      'must',
      'shall',
      'can',
      'that',
      'this',
      'these',
      'those'
    ];

    return word.length > 2 && !commonWords.contains(word);
  }

  bool _isPdfFile(String path) {
    return path.endsWith('.pdf');
  }

  bool _isImageFile(String path) {
    final imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.heic',
      '.heif',
      '.tiff',
      '.tif'
    ];
    return imageExtensions.any((ext) => path.endsWith(ext));
  }

  bool _isTextFile(String path) {
    final textExtensions = [
      '.txt',
      '.md',
      '.json',
      '.xml',
      '.csv',
      '.yaml',
      '.yml',
      '.dart',
      '.java',
      '.kt',
      '.py',
      '.js',
      '.ts',
      '.html',
      '.css',
      '.c',
      '.cpp',
      '.h',
      '.hpp',
      '.rs',
      '.go',
      '.rb',
      '.php',
      '.properties',
      '.conf',
      '.config',
      '.ini',
      '.log'
    ];
    return textExtensions.any((ext) => path.endsWith(ext));
  }

  /// Dispose of resources
  Future<void> dispose() async {
    _textRecognizer.close();
  }
}
