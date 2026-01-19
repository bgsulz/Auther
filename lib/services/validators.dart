import '../models/result.dart';
import 'auth_service.dart';

/// Static validation methods for common data types in Auther.
class Validators {
  Validators._(); // Prevent instantiation

  /// Minimum passphrase length
  static const int minPassphraseLength = 4;

  /// Maximum passphrase length (prevent DoS with PBKDF2)
  static const int maxPassphraseLength = 1000;

  /// Maximum person name length
  static const int maxPersonNameLength = 100;

  /// Validates a passphrase for setting/creating.
  /// Returns Success with the trimmed passphrase, or Failure with error message.
  static Result<String> validatePassphrase(String? passphrase) {
    if (passphrase == null || passphrase.isEmpty) {
      return const Failure('Passphrase cannot be empty');
    }

    final trimmed = passphrase.trim();

    if (trimmed.length < minPassphraseLength) {
      return Failure('Passphrase must be at least $minPassphraseLength characters');
    }

    if (trimmed.length > maxPassphraseLength) {
      return Failure('Passphrase must be at most $maxPassphraseLength characters');
    }

    return Success(trimmed);
  }

  /// Validates a person name.
  /// Returns Success with the trimmed name, or Failure with error message.
  static Result<String> validatePersonName(String? name) {
    if (name == null || name.isEmpty) {
      return const Failure('Name cannot be empty');
    }

    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return const Failure('Name cannot be empty');
    }

    if (trimmed.length > maxPersonNameLength) {
      return Failure('Name must be at most $maxPersonNameLength characters');
    }

    return Success(trimmed);
  }

  /// Validates QR code data from a scan.
  /// Returns Success with parsed data map, or Failure with error message.
  static Result<Map<String, dynamic>> validateQrData(String? qrData) {
    if (qrData == null || qrData.isEmpty) {
      return const Failure('QR code data is empty');
    }

    final parsed = AutherAuth.parseQr(qrData);
    if (parsed == null) {
      return const Failure('Invalid Auther QR code format');
    }

    return Success(parsed);
  }

  /// Validates that a hash is in the expected format.
  /// Returns Success with the hash, or Failure with error message.
  static Result<String> validateHash(String? hash) {
    if (hash == null || hash.isEmpty) {
      return const Failure('Hash cannot be empty');
    }

    if (!AutherAuth.isPlausibleHash(hash)) {
      return const Failure('Invalid hash format');
    }

    return Success(hash);
  }

  /// Validates a QR slot against the current time.
  /// Returns Success if acceptable, Failure otherwise.
  static Result<int> validateSlot(int slot, int nowMillis, {int skew = 2}) {
    if (!AutherAuth.isSlotAcceptable(slot, nowMillis, skew: skew)) {
      return const Failure('QR code has expired');
    }

    return Success(slot);
  }
}
