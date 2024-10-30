import '../customization/config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = SecureStorageService();

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> setPassphrase(String token) async =>
      await _storage.write(key: Config.passphraseKey, value: token);
  Future<String?> getPassphrase() async =>
      await _storage.read(key: Config.passphraseKey);
  Future<void> deletePassphrase() async =>
      await _storage.delete(key: Config.passphraseKey);
}
