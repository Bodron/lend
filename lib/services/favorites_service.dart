import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorite_product_ids';

  static Future<Set<String>> getIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  static Future<bool> toggle(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? const <String>[]).toSet();
    final added = ids.add(productId);
    if (!added) ids.remove(productId);
    await prefs.setStringList(_key, ids.toList());
    return added;
  }
}
