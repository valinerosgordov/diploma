import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:ml_practice/services/sensitive_data_service.dart';

enum ThreatLevel {
  critical('Critical', 4),
  high('High', 3),
  medium('Medium', 2),
  low('Low', 1),
  safe('Safe', 0);

  final String label;
  final int severity;
  const ThreatLevel(this.label, this.severity);
}

enum ThreatType {
  executableFile('Executable file detected'),
  doubleExtension('Suspicious double extension'),
  hiddenFile('Hidden file detected'),
  scriptFile('Script file detected'),
  sensitiveData('Sensitive data found'),
  largeBinary('Unusually large binary file'),
  suspiciousName('Suspicious filename pattern');

  final String description;
  const ThreatType(this.description);
}

class ThreatFinding {
  final ThreatType type;
  final ThreatLevel level;
  final String detail;

  const ThreatFinding({
    required this.type,
    required this.level,
    required this.detail,
  });
}

class ThreatAssessmentResult {
  final ThreatLevel overallLevel;
  final List<ThreatFinding> findings;
  final int riskScore; // 0-100

  const ThreatAssessmentResult({
    required this.overallLevel,
    required this.findings,
    required this.riskScore,
  });

  bool get hasThreat => findings.isNotEmpty;

  static const safe = ThreatAssessmentResult(
    overallLevel: ThreatLevel.safe,
    findings: [],
    riskScore: 0,
  );
}

class ThreatAssessmentService {
  static const _executableExtensions = {
    'exe', 'bat', 'cmd', 'com', 'msi', 'scr', 'pif',
    'vbs', 'vbe', 'wsf', 'wsh', 'ps1', 'cpl',
  };

  static const _scriptExtensions = {
    'sh', 'bash', 'py', 'rb', 'pl', 'js',
  };

  static const _suspiciousNamePatterns = [
    'crack', 'keygen', 'hack', 'exploit', 'payload',
    'trojan', 'malware', 'backdoor', 'rootkit',
  ];

  static const _doubleExtensionTriggers = {
    'exe', 'bat', 'cmd', 'scr', 'pif', 'com', 'vbs', 'js',
  };

  static const int _largeBinaryThreshold = 100 * 1024 * 1024; // 100 MB

  Future<void> initialize() async {}

  Future<ThreatAssessmentResult> assessFile(
    File file, {
    SensitiveDataResult? sensitiveData,
  }) async {
    try {
      final findings = <ThreatFinding>[];
      final filename = p.basename(file.path).toLowerCase();
      final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();

      // 1. Executable check
      if (_executableExtensions.contains(ext)) {
        findings.add(ThreatFinding(
          type: ThreatType.executableFile,
          level: ThreatLevel.high,
          detail: 'File "$filename" is an executable ($ext)',
        ));
      }

      // 2. Script check
      if (_scriptExtensions.contains(ext)) {
        findings.add(ThreatFinding(
          type: ThreatType.scriptFile,
          level: ThreatLevel.medium,
          detail: 'File "$filename" is a script ($ext)',
        ));
      }

      // 3. Double extension (e.g., report.pdf.exe)
      final nameWithoutExt = p.basenameWithoutExtension(file.path);
      final innerExt =
          p.extension(nameWithoutExt).replaceFirst('.', '').toLowerCase();
      if (innerExt.isNotEmpty && _doubleExtensionTriggers.contains(ext)) {
        findings.add(ThreatFinding(
          type: ThreatType.doubleExtension,
          level: ThreatLevel.critical,
          detail:
              'File "$filename" has suspicious double extension (.$innerExt.$ext)',
        ));
      }

      // 4. Hidden file (starts with .)
      if (p.basename(file.path).startsWith('.')) {
        findings.add(ThreatFinding(
          type: ThreatType.hiddenFile,
          level: ThreatLevel.low,
          detail: 'File "$filename" is hidden',
        ));
      }

      // 5. Suspicious filename
      for (final pattern in _suspiciousNamePatterns) {
        if (filename.contains(pattern)) {
          findings.add(ThreatFinding(
            type: ThreatType.suspiciousName,
            level: ThreatLevel.high,
            detail:
                'File "$filename" contains suspicious keyword "$pattern"',
          ));
          break;
        }
      }

      // 6. Large binary
      final stat = await file.stat();
      if (stat.size > _largeBinaryThreshold) {
        findings.add(ThreatFinding(
          type: ThreatType.largeBinary,
          level: ThreatLevel.medium,
          detail:
              'File "$filename" is ${(stat.size / (1024 * 1024)).toStringAsFixed(0)} MB',
        ));
      }

      // 7. Sensitive data findings
      if (sensitiveData != null && sensitiveData.hasSensitiveData) {
        final count = sensitiveData.totalFindings;
        final level =
            count > 5 ? ThreatLevel.high : ThreatLevel.medium;
        findings.add(ThreatFinding(
          type: ThreatType.sensitiveData,
          level: level,
          detail: '$count sensitive data item(s) found in "$filename"',
        ));
      }

      // Calculate overall
      if (findings.isEmpty) return ThreatAssessmentResult.safe;

      final maxLevel = findings
          .map((f) => f.level)
          .reduce((a, b) => a.severity >= b.severity ? a : b);

      final riskScore = _calculateRiskScore(findings);

      return ThreatAssessmentResult(
        overallLevel: maxLevel,
        findings: findings,
        riskScore: riskScore,
      );
    } catch (e) {
      debugPrint('Error assessing file threat: $e');
      return ThreatAssessmentResult.safe;
    }
  }

  int _calculateRiskScore(List<ThreatFinding> findings) {
    double score = 0;
    for (final finding in findings) {
      score += switch (finding.level) {
        ThreatLevel.critical => 40,
        ThreatLevel.high => 25,
        ThreatLevel.medium => 15,
        ThreatLevel.low => 5,
        ThreatLevel.safe => 0,
      };
    }
    return score.clamp(0, 100).toInt();
  }

  /// Aggregate threat level from all file assessments
  static ThreatLevel aggregateLevel(List<ThreatAssessmentResult> results) {
    if (results.isEmpty) return ThreatLevel.safe;

    final maxSeverity = results
        .map((r) => r.overallLevel.severity)
        .reduce((a, b) => a > b ? a : b);

    return ThreatLevel.values.firstWhere(
      (l) => l.severity == maxSeverity,
      orElse: () => ThreatLevel.safe,
    );
  }

  void dispose() {}
}
