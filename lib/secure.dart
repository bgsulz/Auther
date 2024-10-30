import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> setPassphrase(String token) async =>
      await _storage.write(key: 'passphrase', value: token);
  Future<String?> getPassphrase() async =>
      await _storage.read(key: 'passphrase');
  Future<void> deletePassphrase() async =>
      await _storage.delete(key: 'passphrase');
}
