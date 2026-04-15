import 'package:flutter/material.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/services/sensitive_data_service.dart';
import 'package:ml_practice/services/threat_assessment_service.dart';

class SensitiveDataWidget extends StatelessWidget {
  final SensitiveDataResult result;

  const SensitiveDataWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.hasSensitiveData) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.privacy_tip, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sensitive Data (${result.totalFindings} found)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Summary by type
          ...result.summary.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    _iconForType(entry.key),
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key.label}: ${entry.value}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Individual matches (first 5)
          ...result.matches.take(5).map(
                (match) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Line ${match.line}: ${match.maskedValue}',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          if (result.matches.length > 5)
            Text(
              '... and ${result.matches.length - 5} more',
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(SensitiveDataType type) {
    return switch (type) {
      SensitiveDataType.email => Icons.email,
      SensitiveDataType.phoneNumber => Icons.phone,
      SensitiveDataType.creditCard => Icons.credit_card,
      SensitiveDataType.ipAddress => Icons.lan,
      SensitiveDataType.apiKey => Icons.key,
      SensitiveDataType.password => Icons.lock,
      SensitiveDataType.privateKey => Icons.vpn_key,
      SensitiveDataType.jwtToken => Icons.token,
    };
  }
}

class ThreatIndicatorWidget extends StatelessWidget {
  final ThreatAssessmentResult result;

  const ThreatIndicatorWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.hasThreat) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.shield, color: _colorForLevel(result.overallLevel), size: 16),
          const SizedBox(width: 4),
          Text(
            'Risk: ${result.overallLevel.label}',
            style: TextStyle(
              color: _colorForLevel(result.overallLevel),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorForLevel(ThreatLevel level) {
    return switch (level) {
      ThreatLevel.critical => const Color(0xFFDC2626),
      ThreatLevel.high => AppColors.error,
      ThreatLevel.medium => AppColors.warning,
      ThreatLevel.low => const Color(0xFF60A5FA),
      ThreatLevel.safe => AppColors.success,
    };
  }
}

class ThreatAnalysisWidget extends StatelessWidget {
  final ThreatAssessmentResult result;

  const ThreatAnalysisWidget({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (!result.hasThreat) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield,
                color: ThreatIndicatorWidget._colorForLevel(result.overallLevel),
              ),
              const SizedBox(width: 8),
              Text(
                'Threat Level: ${result.overallLevel.label} (Score: ${result.riskScore})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ThreatIndicatorWidget._colorForLevel(result.overallLevel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Risk score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: result.riskScore / 100,
              backgroundColor: AppColors.inputBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                ThreatIndicatorWidget._colorForLevel(result.overallLevel),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          // Findings
          ...result.findings.map(
            (finding) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: ThreatIndicatorWidget._colorForLevel(finding.level),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      finding.detail,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
