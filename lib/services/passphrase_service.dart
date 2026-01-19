import 'dart:convert';
import '../models/result.dart';
import '../repositories/secure_storage_repository.dart';
import '../services/validators.dart';
import 'auth_service.dart';
import 'logger.dart';

/// Service for handling passphrase operations (set, validate, delete).
/// Extracted from AutherState to provide a focused, testable service.
class PassphraseService {
  final SecureStorageService _secureStorage;

  PassphraseService({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  /// Sets a new passphrase and returns the derived key hex.
  /// Returns Success with the derivedKeyHex, or Failure with error message.
  Future<Result<String>> setPassphrase(String passphrase) async {
    final validation = Validators.validatePassphrase(passphrase);
    if (validation.isFailure) {
      return Failure(validation.errorOrNull ?? 'Invalid passphrase');
    }

    try {
      final rec = AutherAuth.deriveCredentials(validation.valueOrNull!);
      await _secureStorage.setPassphrase(jsonEncode(rec));
      final derivedKeyHex = rec['derivedKeyHex'] as String;
      logger.info('Passphrase set successfully', 'PassphraseService');
      return Success(derivedKeyHex);
    } catch (e) {
      logger.error('Failed to set passphrase', e, null, 'PassphraseService');
      return Failure('Failed to set passphrase', e);
    }
  }

  /// Validates a passphrase against stored credentials.
  /// Returns Success(true) if valid, Success(false) if invalid,
  /// or Failure if there's an error.
  Future<Result<bool>> validatePassphrase(String passphrase) async {
    try {
      final stored = await _secureStorage.getPassphrase();
      if (stored == null || stored.isEmpty) {
        return const Success(false);
      }

      try {
        final rec = jsonDecode(stored) as Map<String, dynamic>;
        final isValid = AutherAuth.verifyPassphrase(passphrase, rec);
        return Success(isValid);
      } catch (_) {
        // Legacy format fallback removed per plan - just return false
        logger.warn('Legacy passphrase format encountered', 'PassphraseService');
        return const Success(false);
      }
    } catch (e) {
      logger.error('Failed to validate passphrase', e, null, 'PassphraseService');
      return Failure('Failed to validate passphrase', e);
    }
  }

  /// Gets the stored derived key hex from secure storage.
  /// Returns Success with the hash, Success with empty string if none,
  /// or Failure on error.
  Future<Result<String>> getStoredHash() async {
    try {
      final stored = await _secureStorage.getPassphrase();
      if (stored == null || stored.isEmpty) {
        return const Success('');
      }

      try {
        final rec = jsonDecode(stored) as Map<String, dynamic>;
        final hash = rec['derivedKeyHex'] as String? ?? '';
        return Success(hash);
      } catch (_) {
        // Legacy format - return as-is (will fail validation anyway)
        return Success(stored);
      }
    } catch (e) {
      logger.error('Failed to get stored hash', e, null, 'PassphraseService');
      return Failure('Failed to retrieve stored credentials', e);
    }
  }

  /// Checks if a passphrase has been set.
  Future<bool> hasPassphrase() async {
    final result = await getStoredHash();
    return result.isSuccess && (result.valueOrNull?.isNotEmpty ?? false);
  }

  /// Deletes the stored passphrase.
  Future<Result<void>> deletePassphrase() async {
    try {
      await _secureStorage.deletePassphrase();
      logger.info('Passphrase deleted', 'PassphraseService');
      return const Success(null);
    } catch (e) {
      logger.error('Failed to delete passphrase', e, null, 'PassphraseService');
      return Failure('Failed to delete passphrase', e);
    }
  }
}
