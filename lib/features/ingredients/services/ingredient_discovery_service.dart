import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/utils/search_utils.dart';

String ingredientNameKey(String name) =>
    searchKey(name).replaceAll(RegExp(r'\s+'), ' ').trim();

String discoveredIngredientId(String name) =>
    'ai_${sha256.convert(utf8.encode(ingredientNameKey(name)))}';

abstract interface class IngredientDiscoveryService {
  Future<void> saveDiscovered(String requestId, Iterable<String> names);
}
