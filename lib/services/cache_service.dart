import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static final Box _box = Hive.box('cacheBox');

  // Save any data (can be String, Map, List, etc.)
  static Future<void> save(String key, dynamic value) async {
    await _box.put(key, value);
  }

  // Load data by key
  static dynamic load(String key) {
    return _box.get(key);
  }

  // Remove a cached key
  static Future<void> remove(String key) async {
    await _box.delete(key);
  }

  // Clear all cache
  static Future<void> clear() async {
    await _box.clear();
  }
}
