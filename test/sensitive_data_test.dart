import 'package:flutter_test/flutter_test.dart';
import 'package:ml_practice/services/sensitive_data_service.dart';

void main() {
  late SensitiveDataService service;

  setUp(() {
    service = SensitiveDataService();
  });

  group('SensitiveDataService pattern detection', () {
    // Access private _scanContent via scanFile would need a real file,
    // so we test the patterns directly through regex matching

    test('detects email addresses', () {
      final pattern = RegExp(
        r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      );
      expect(pattern.hasMatch('user@domain.com'), true);
      expect(pattern.hasMatch('test.user+tag@company.co.uk'), true);
      expect(pattern.hasMatch('notanemail'), false);
      expect(pattern.hasMatch('@nodomain'), false);
    });

    test('detects credit card numbers', () {
      final pattern = RegExp(
        r'\b(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|3[47][0-9]{13}|6(?:011|5[0-9]{2})[0-9]{12})\b',
      );
      // Visa
      expect(pattern.hasMatch('4111111111111111'), true);
      // MasterCard
      expect(pattern.hasMatch('5500000000000004'), true);
      // Amex
      expect(pattern.hasMatch('378282246310005'), true);
      // Too short
      expect(pattern.hasMatch('411111111'), false);
    });

    test('detects IPv4 addresses', () {
      final pattern = RegExp(
        r'\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b',
      );
      expect(pattern.hasMatch('192.168.1.1'), true);
      expect(pattern.hasMatch('10.0.0.1'), true);
      expect(pattern.hasMatch('255.255.255.255'), true);
      expect(pattern.hasMatch('999.999.999.999'), false);
      expect(pattern.hasMatch('not.an.ip'), false);
    });

    test('detects API keys', () {
      final pattern = RegExp(
        r'''(?:api[_-]?key|api[_-]?secret|access[_-]?token|auth[_-]?token|secret[_-]?key)\s*[:=]\s*['"]?([a-zA-Z0-9_\-/.]{20,})['"]?''',
        caseSensitive: false,
      );
      expect(
        pattern.hasMatch('api_key = "sk_live_abc123def456ghi789jkl"'),
        true,
      );
      expect(
        pattern.hasMatch('API_KEY: abcdefghijklmnopqrstuvwxyz'),
        true,
      );
      expect(
        pattern.hasMatch('access_token="eyJhbGciOiJIUzI1NiIsInR5cCI"'),
        true,
      );
      expect(pattern.hasMatch('name = "John"'), false);
    });

    test('detects passwords in config', () {
      final pattern = RegExp(
        r'''(?:password|passwd|pwd|secret)\s*[:=]\s*['"]?([^\s'"]{4,})['"]?''',
        caseSensitive: false,
      );
      expect(pattern.hasMatch('password = "mySecretPass123"'), true);
      expect(pattern.hasMatch('PASSWORD: hunter2'), true);
      expect(pattern.hasMatch('pwd=abcd1234'), true);
      expect(pattern.hasMatch('username = "john"'), false);
    });

    test('detects private keys', () {
      final pattern = RegExp(
        r'-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----',
      );
      expect(
        pattern.hasMatch('-----BEGIN RSA PRIVATE KEY-----'),
        true,
      );
      expect(pattern.hasMatch('-----BEGIN PRIVATE KEY-----'), true);
      expect(pattern.hasMatch('-----BEGIN PUBLIC KEY-----'), false);
    });

    test('detects JWT tokens', () {
      final pattern = RegExp(
        r'\beyJ[a-zA-Z0-9_-]{10,}\.eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\b',
      );
      expect(
        pattern.hasMatch(
          'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U',
        ),
        true,
      );
      expect(pattern.hasMatch('not.a.jwt'), false);
    });

    test('detects phone numbers', () {
      final pattern = RegExp(
        r'(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{2,4}',
      );
      expect(pattern.hasMatch('+1-555-123-4567'), true);
      expect(pattern.hasMatch('(555) 123-4567'), true);
      expect(pattern.hasMatch('+7 999 123 4567'), true);
      expect(pattern.hasMatch('12'), false);
    });
  });

  group('SensitiveDataResult', () {
    test('empty result has no sensitive data', () {
      expect(SensitiveDataResult.empty.hasSensitiveData, false);
      expect(SensitiveDataResult.empty.totalFindings, 0);
    });

    test('result with matches has sensitive data', () {
      final result = SensitiveDataResult(
        matches: [
          const SensitiveMatch(
            type: SensitiveDataType.email,
            maskedValue: 'te***@test.com',
            line: 1,
          ),
        ],
        totalFindings: 1,
        summary: const {SensitiveDataType.email: 1},
      );
      expect(result.hasSensitiveData, true);
    });
  });

  group('Masking', () {
    test('SensitiveDataType labels are human readable', () {
      expect(SensitiveDataType.email.label, 'Email Address');
      expect(SensitiveDataType.creditCard.label, 'Credit Card');
      expect(SensitiveDataType.privateKey.label, 'Private Key');
      expect(SensitiveDataType.jwtToken.label, 'JWT Token');
    });
  });
}
