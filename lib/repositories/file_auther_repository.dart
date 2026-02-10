import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../repositories/auther_repository.dart';

class FileAutherRepository implements AutherRepository {
  Future<File> get _dataFile async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/data.json');
    if (!await file.exists()) {
      await file.writeAsString('{}');
    }
    return file;
  }

  @override
  Future<String?> loadData() async {
    try {
      final file = await _dataFile;
      final contents = await file.readAsString();
      return contents.isEmpty ? '{}' : contents;
    } on FileSystemException catch (e) {
      throw FileSystemException('Failed to read data file', e.path, e.osError);
    }
  }

  @override
  Future<void> saveData(String json) async {
    try {
      final file = await _dataFile;
      await file.writeAsString(json);
    } on FileSystemException catch (e) {
      throw FileSystemException('Failed to write data file', e.path, e.osError);
    }
  }

  @override
  Future<void> deleteAll() async {
    final file = await _dataFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
