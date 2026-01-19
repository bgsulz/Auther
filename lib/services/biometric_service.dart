import 'package:local_auth/local_auth.dart';
import 'package:auther/services/logger.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometrics
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      logger.info('[Biometric] isAvailable: canCheck=$canCheck, isSupported=$isSupported', 'BiometricService');
      return canCheck && isSupported;
    } catch (e) {
      logger.error('[Biometric] isAvailable error', e, null, 'BiometricService');
      return false;
    }
  }

  /// Check what types of biometrics are available
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      logger.info('[Biometric] availableTypes=$types', 'BiometricService');
      return types;
    } catch (e) {
      logger.error('[Biometric] getAvailableBiometrics error', e, null, 'BiometricService');
      return [];
    }
  }

  /// Perform biometric authentication
  Future<bool> authenticate() async {
    logger.info('[Biometric] authenticate() called', 'BiometricService');
    try {
      final result = await _auth.authenticate(
        localizedReason: 'Authenticate to unlock Auther',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      logger.info('[Biometric] authenticate result=$result', 'BiometricService');
      return result;
    } catch (e) {
      logger.error('[Biometric] authenticate error', e, null, 'BiometricService');
      return false;
    }
  }
}
