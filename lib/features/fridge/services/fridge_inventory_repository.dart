abstract interface class FridgeInventoryRepository {
  Future<List<String>> read();
  Future<void> save(List<String> ingredientIds);
}
