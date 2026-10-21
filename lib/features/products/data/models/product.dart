class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = rawImages is List
        ? rawImages
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
        : const <String>[];
    final thumbnail = _asText(json['thumbnail']);

    return Product(
      id: _asInt(json['id']) ?? 0,
      title: _asText(json['title'], fallback: 'Untitled product'),
      description: _asText(
        json['description'],
        fallback: 'No description available.',
      ),
      price: _asDouble(json['price']) ?? 0,
      imageUrl: thumbnail.isNotEmpty
          ? thumbnail
          : (images.isNotEmpty ? images.first : ''),
    );
  }

  final int id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static String _asText(Object? value, {String fallback = ''}) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }
}
