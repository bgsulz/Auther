abstract class AutherRepository {
  Future<void> saveData(String json);
  Future<String?> loadData();
  Future<void> deleteAll();
}
