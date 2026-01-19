import 'package:flutter_test/flutter_test.dart';
import 'package:auther/services/auth_service.dart';
import 'package:auther/customization/words.dart';

void main() {
  group('AutherAuth', () {
    group('hashPassphrase', () {
      test('returns consistent hash for same input', () {
        final hash1 = AutherAuth.hashPassphrase('test123');
        final hash2 = AutherAuth.hashPassphrase('test123');
        expect(hash1, hash2);
      });

      test('returns different hash for different input', () {
        final hash1 = AutherAuth.hashPassphrase('test123');
        final hash2 = AutherAuth.hashPassphrase('test456');
        expect(hash1, isNot(hash2));
      });

      test('returns 64-character hex string', () {
        final hash = AutherAuth.hashPassphrase('test');
        expect(hash.length, 64);
        expect(RegExp(r'^[0-9a-f]+$').hasMatch(hash), true);
      });
    });

    group('isPlausibleHash', () {
      test('returns true for valid 64-char hex', () {
        final validHash = 'a' * 64;
        expect(AutherAuth.isPlausibleHash(validHash), true);
      });

      test('returns false for wrong length', () {
        expect(AutherAuth.isPlausibleHash('abc123'), false);
        expect(AutherAuth.isPlausibleHash('a' * 63), false);
        expect(AutherAuth.isPlausibleHash('a' * 65), false);
      });

      test('returns false for non-hex characters', () {
        expect(AutherAuth.isPlausibleHash('g' * 64), false);
        expect(AutherAuth.isPlausibleHash('A' * 64), false); // uppercase not allowed
      });
    });

    group('getOTP', () {
      test('returns three words', () {
        final hash1 = 'a' * 64;
        final hash2 = 'b' * 64;
        final otp = AutherAuth.getOTP(hash1, hash2, 12345);
        final words = otp.split(' ');
        expect(words.length, 3);
      });

      test('returns same OTP for same inputs', () {
        final hash1 = 'a' * 64;
        final hash2 = 'b' * 64;
        final otp1 = AutherAuth.getOTP(hash1, hash2, 12345);
        final otp2 = AutherAuth.getOTP(hash1, hash2, 12345);
        expect(otp1, otp2);
      });

      test('returns different OTP for different seeds', () {
        final hash1 = 'a' * 64;
        final hash2 = 'b' * 64;
        final otp1 = AutherAuth.getOTP(hash1, hash2, 12345);
        final otp2 = AutherAuth.getOTP(hash1, hash2, 12346);
        expect(otp1, isNot(otp2));
      });

      test('returns words from the word list', () {
        final hash1 = 'a' * 64;
        final hash2 = 'b' * 64;
        final otp = AutherAuth.getOTP(hash1, hash2, 12345);
        final words = otp.split(' ');
        for (final word in words) {
          expect(Words.words.contains(word), true,
              reason: '$word should be in word list');
        }
      });

      test('handles edge case indices with modulo', () {
        // This test verifies the bounds check fix
        // Try many seeds to exercise different index values
        final hash1 = 'a' * 64;
        final hash2 = 'b' * 64;
        for (int seed = 0; seed < 1000; seed++) {
          expect(() => AutherAuth.getOTP(hash1, hash2, seed), returnsNormally);
        }
      });
    });

    group('QR encoding/parsing', () {
      test('qrEncode produces valid format', () {
        final hash = 'a' * 64;
        final encoded = AutherAuth.qrEncode(hash, 12345);
        expect(encoded, 'AutherX:12345:$hash');
      });

      test('parseQr extracts slot and hash', () {
        final hash = 'a' * 64;
        final qr = 'AutherX:12345:$hash';
        final parsed = AutherAuth.parseQr(qr);
        expect(parsed, isNotNull);
        expect(parsed!['slot'], 12345);
        expect(parsed['userHash'], hash);
      });

      test('parseQr returns null for invalid format', () {
        expect(AutherAuth.parseQr('invalid'), null);
        expect(AutherAuth.parseQr('AutherX:'), null);
        expect(AutherAuth.parseQr('AutherX:abc:def'), null);
        expect(AutherAuth.parseQr('AutherX:123:short'), null);
      });
    });

    group('isSlotAcceptable', () {
      test('accepts current slot', () {
        final now = DateTime.now().millisecondsSinceEpoch;
        final currentSlot = AutherAuth.currentSlot(now);
        expect(AutherAuth.isSlotAcceptable(currentSlot, now), true);
      });

      test('accepts slot within skew', () {
        final now = DateTime.now().millisecondsSinceEpoch;
        final currentSlot = AutherAuth.currentSlot(now);
        expect(AutherAuth.isSlotAcceptable(currentSlot - 1, now, skew: 1), true);
        expect(AutherAuth.isSlotAcceptable(currentSlot + 1, now, skew: 1), true);
      });

      test('rejects slot outside skew', () {
        final now = DateTime.now().millisecondsSinceEpoch;
        final currentSlot = AutherAuth.currentSlot(now);
        expect(AutherAuth.isSlotAcceptable(currentSlot - 2, now, skew: 1), false);
        expect(AutherAuth.isSlotAcceptable(currentSlot + 2, now, skew: 1), false);
      });

      test('accepts slot with skew of 2', () {
        final now = DateTime.now().millisecondsSinceEpoch;
        final currentSlot = AutherAuth.currentSlot(now);
        expect(AutherAuth.isSlotAcceptable(currentSlot - 2, now, skew: 2), true);
        expect(AutherAuth.isSlotAcceptable(currentSlot + 2, now, skew: 2), true);
      });
    });

    group('PBKDF2 credentials', () {
      test('deriveCredentials produces expected structure', () {
        final creds = AutherAuth.deriveCredentials('testpassword');
        expect(creds['algo'], 'pbkdf2-hmac-sha256');
        expect(creds['iterations'], AutherAuth.kdfIterations);
        expect(creds['version'], AutherAuth.kdfVersion);
        expect(creds['saltB64'], isA<String>());
        expect(creds['derivedKeyHex'], isA<String>());
        expect((creds['derivedKeyHex'] as String).length, 64);
      });

      test('verifyPassphrase returns true for correct password', () {
        final creds = AutherAuth.deriveCredentials('mypassword');
        expect(AutherAuth.verifyPassphrase('mypassword', creds), true);
      });

      test('verifyPassphrase returns false for wrong password', () {
        final creds = AutherAuth.deriveCredentials('mypassword');
        expect(AutherAuth.verifyPassphrase('wrongpassword', creds), false);
      });

      test('different salts produce different derived keys', () {
        final creds1 = AutherAuth.deriveCredentials('samepassword');
        final creds2 = AutherAuth.deriveCredentials('samepassword');
        // Salts should be different (random)
        expect(creds1['saltB64'], isNot(creds2['saltB64']));
        // Derived keys should also be different
        expect(creds1['derivedKeyHex'], isNot(creds2['derivedKeyHex']));
      });
    });
  });
}
