import 'package:shared_preferences/shared_preferences.dart';

class PasarFavoriteService {
  static final PasarFavoriteService _instance =
      PasarFavoriteService._internal();
  factory PasarFavoriteService() => _instance;
  PasarFavoriteService._internal();

  static const String _productFavKey = 'pasar_favorite_products';
  static const String _storeFavKey = 'pasar_favorite_stores';

  // --- PRODUCT FAVORITES ---

  Future<List<int>> getFavoriteProductIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(_productFavKey) ?? [];
    return stringList
        .map((e) => int.tryParse(e) ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  Future<bool> isProductFavorite(int productId) async {
    final ids = await getFavoriteProductIds();
    return ids.contains(productId);
  }

  Future<bool> toggleProductFavorite(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getFavoriteProductIds();
    bool isNowFav;

    if (ids.contains(productId)) {
      ids.remove(productId);
      isNowFav = false;
    } else {
      ids.add(productId);
      isNowFav = true;
    }

    await prefs.setStringList(
      _productFavKey,
      ids.map((id) => id.toString()).toList(),
    );
    return isNowFav;
  }

  // --- STORE FAVORITES ---

  Future<List<String>> getFavoriteStoreNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storeFavKey) ?? [];
  }

  Future<bool> isStoreFavorite(String storeName) async {
    final stores = await getFavoriteStoreNames();
    return stores.contains(storeName);
  }

  Future<bool> toggleStoreFavorite(String storeName) async {
    final prefs = await SharedPreferences.getInstance();
    final stores = await getFavoriteStoreNames();
    bool isNowFav;

    if (stores.contains(storeName)) {
      stores.remove(storeName);
      isNowFav = false;
    } else {
      stores.add(storeName);
      isNowFav = true;
    }

    await prefs.setStringList(_storeFavKey, stores);
    return isNowFav;
  }
}
