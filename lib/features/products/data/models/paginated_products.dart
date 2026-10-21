import 'product.dart';

/// Represents a paginated product response from DummyJSON.
class PaginatedProducts {
  const PaginatedProducts({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory PaginatedProducts.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'];
    final products = rawProducts is List
        ? rawProducts
            .whereType<Map>()
            .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <Product>[];

    final total = _asInt(json['total']) ?? products.length;
    final skip = _asInt(json['skip']) ?? 0;
    final limit = _asInt(json['limit']) ?? products.length;

    return PaginatedProducts(
      products: products,
      total: total,
      skip: skip,
      limit: limit,
    );
  }

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  bool get hasMore => (skip + products.length) < total;

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
