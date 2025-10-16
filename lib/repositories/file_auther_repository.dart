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
    final file = await _dataFile;
    final contents = await file.readAsString();
    return contents.isEmpty ? '{}' : contents;
  }

  @override
  Future<void> saveData(String json) async {
    final file = await _dataFile;
    await file.writeAsString(json);
  }

  @override
  Future<void> deleteAll() async {
    final file = await _dataFile;
    if (await file.exists()) {
      await file.delete();
    }
  }
}
