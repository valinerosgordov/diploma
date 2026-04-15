import 'package:flutter_test/flutter_test.dart';
import 'package:ml_practice/services/threat_assessment_service.dart';

void main() {
  group('ThreatLevel', () {
    test('severity ordering is correct', () {
      expect(ThreatLevel.critical.severity, greaterThan(ThreatLevel.high.severity));
      expect(ThreatLevel.high.severity, greaterThan(ThreatLevel.medium.severity));
      expect(ThreatLevel.medium.severity, greaterThan(ThreatLevel.low.severity));
      expect(ThreatLevel.low.severity, greaterThan(ThreatLevel.safe.severity));
    });

    test('labels are human readable', () {
      expect(ThreatLevel.critical.label, 'Critical');
      expect(ThreatLevel.safe.label, 'Safe');
    });
  });

  group('ThreatAssessmentResult', () {
    test('safe result has no threats', () {
      expect(ThreatAssessmentResult.safe.hasThreat, false);
      expect(ThreatAssessmentResult.safe.riskScore, 0);
      expect(ThreatAssessmentResult.safe.overallLevel, ThreatLevel.safe);
    });

    test('result with findings has threats', () {
      const result = ThreatAssessmentResult(
        overallLevel: ThreatLevel.high,
        findings: [
          ThreatFinding(
            type: ThreatType.executableFile,
            level: ThreatLevel.high,
            detail: 'test.exe is executable',
          ),
        ],
        riskScore: 25,
      );
      expect(result.hasThreat, true);
      expect(result.riskScore, 25);
    });
  });

  group('ThreatType', () {
    test('descriptions are set', () {
      expect(
        ThreatType.doubleExtension.description,
        'Suspicious double extension',
      );
      expect(
        ThreatType.executableFile.description,
        'Executable file detected',
      );
      expect(
        ThreatType.sensitiveData.description,
        'Sensitive data found',
      );
    });
  });

  group('ThreatAssessmentService.aggregateLevel', () {
    test('returns safe for empty list', () {
      expect(
        ThreatAssessmentService.aggregateLevel([]),
        ThreatLevel.safe,
      );
    });

    test('returns highest level from results', () {
      final results = [
        ThreatAssessmentResult.safe,
        const ThreatAssessmentResult(
          overallLevel: ThreatLevel.medium,
          findings: [
            ThreatFinding(
              type: ThreatType.scriptFile,
              level: ThreatLevel.medium,
              detail: 'test',
            ),
          ],
          riskScore: 15,
        ),
        const ThreatAssessmentResult(
          overallLevel: ThreatLevel.high,
          findings: [
            ThreatFinding(
              type: ThreatType.executableFile,
              level: ThreatLevel.high,
              detail: 'test',
            ),
          ],
          riskScore: 25,
        ),
      ];
      expect(
        ThreatAssessmentService.aggregateLevel(results),
        ThreatLevel.high,
      );
    });
  });
}
