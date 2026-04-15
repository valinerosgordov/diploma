import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ml_practice/models/file_type_mappings.dart';

enum SensitiveDataType {
  email('Email Address'),
  phoneNumber('Phone Number'),
  creditCard('Credit Card'),
  ipAddress('IP Address'),
  apiKey('API Key'),
  password('Password/Secret'),
  privateKey('Private Key'),
  jwtToken('JWT Token');

  final String label;
  const SensitiveDataType(this.label);
}

class SensitiveMatch {
  final SensitiveDataType type;
  final String maskedValue;
  final int line;

  const SensitiveMatch({
    required this.type,
    required this.maskedValue,
    required this.line,
  });
}

class SensitiveDataResult {
  final List<SensitiveMatch> matches;
  final int totalFindings;
  final Map<SensitiveDataType, int> summary;

  const SensitiveDataResult({
    required this.matches,
    required this.totalFindings,
    required this.summary,
  });

  bool get hasSensitiveData => totalFindings > 0;

  static const empty = SensitiveDataResult(
    matches: [],
    totalFindings: 0,
    summary: {},
  );
}

class SensitiveDataService {
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB limit

  static final _patterns = <SensitiveDataType, RegExp>{
    // Email
    SensitiveDataType.email: RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    ),
    // Phone numbers (international formats)
    SensitiveDataType.phoneNumber: RegExp(
      r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{2,4}',
    ),
    // Credit card (Visa, MC, Amex patterns)
    SensitiveDataType.creditCard: RegExp(
      r'\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\b',
    ),
    // IPv4 addresses
    SensitiveDataType.ipAddress: RegExp(
      r'\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b',
    ),
    // API keys (generic patterns — hex/base64 strings 20+ chars after key-like words)
    SensitiveDataType.apiKey: RegExp(
      r'''(?:api[_-]?key|api[_-]?secret|access[_-]?token|auth[_-]?token|secret[_-]?key)\s*[:=]\s*['"]?([a-zA-Z0-9_\-/.]{20,})['"]?''',
      caseSensitive: false,
    ),
    // Passwords in config/code
    SensitiveDataType.password: RegExp(
      r'''(?:password|passwd|pwd|secret)\s*[:=]\s*['"]?([^\s'"]{4,})['"]?''',
      caseSensitive: false,
    ),
    // Private keys (PEM format)
    SensitiveDataType.privateKey: RegExp(
      r'-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----',
    ),
    // JWT tokens
    SensitiveDataType.jwtToken: RegExp(
      r'\beyJ[a-zA-Z0-9_-]{10,}\.eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\b',
    ),
  };

  Future<void> initialize() async {}

  Future<SensitiveDataResult> scanFile(File file) async {
    try {
      // Skip non-text files and large files
      if (!FileTypeMappings.isTextFile(file.path) &&
          !FileTypeMappings.isPdfFile(file.path)) {
        return SensitiveDataResult.empty;
      }

      final stat = await file.stat();
      if (stat.size > _maxFileSizeBytes) {
        return SensitiveDataResult.empty;
      }

      final content = await file.readAsString();
      return _scanContent(content);
    } catch (e) {
      debugPrint('Error scanning file for sensitive data: $e');
      return SensitiveDataResult.empty;
    }
  }

  SensitiveDataResult _scanContent(String content) {
    final matches = <SensitiveMatch>[];
    final summary = <SensitiveDataType, int>{};
    final lines = content.split('\n');

    for (final entry in _patterns.entries) {
      final type = entry.key;
      final pattern = entry.value;

      for (int i = 0; i < lines.length; i++) {
        final lineMatches = pattern.allMatches(lines[i]);
        for (final match in lineMatches) {
          // Skip common false positives
          if (_isFalsePositive(type, match.group(0)!)) continue;

          matches.add(SensitiveMatch(
            type: type,
            maskedValue: _maskValue(type, match.group(0)!),
            line: i + 1,
          ));
          summary[type] = (summary[type] ?? 0) + 1;
        }
      }
    }

    return SensitiveDataResult(
      matches: matches,
      totalFindings: matches.length,
      summary: summary,
    );
  }

  bool _isFalsePositive(SensitiveDataType type, String value) {
    switch (type) {
      case SensitiveDataType.ipAddress:
        // Skip loopback and common internal
        return value == '127.0.0.1' ||
            value == '0.0.0.0' ||
            value.startsWith('192.168.') ||
            value.startsWith('10.') ||
            value == '255.255.255.0';
      case SensitiveDataType.phoneNumber:
        // Too short = likely not a phone number
        final digits = value.replaceAll(RegExp(r'\D'), '');
        return digits.length < 7;
      case SensitiveDataType.email:
        // Skip example emails
        return value.endsWith('@example.com') ||
            value.endsWith('@test.com') ||
            value.endsWith('@localhost');
      default:
        return false;
    }
  }

  String _maskValue(SensitiveDataType type, String value) {
    switch (type) {
      case SensitiveDataType.email:
        final parts = value.split('@');
        if (parts.length != 2) return '***';
        final name = parts[0];
        final masked = name.length > 2
            ? '${name.substring(0, 2)}***'
            : '***';
        return '$masked@${parts[1]}';
      case SensitiveDataType.creditCard:
        return '****-****-****-${value.substring(value.length - 4)}';
      case SensitiveDataType.phoneNumber:
        if (value.length > 4) {
          return '${'*' * (value.length - 4)}${value.substring(value.length - 4)}';
        }
        return '***';
      case SensitiveDataType.apiKey:
      case SensitiveDataType.password:
      case SensitiveDataType.jwtToken:
        return '${value.substring(0, value.length.clamp(0, 8))}${'*' * 12}';
      case SensitiveDataType.privateKey:
        return '-----BEGIN PRIVATE KEY----- [REDACTED]';
      case SensitiveDataType.ipAddress:
        return value; // IPs are not masked — they're structural
    }
  }

  void dispose() {}
}
