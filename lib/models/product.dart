class Product {
  final int? id;
  final String name;
  final String brand;
  final String category;
  final String? code;
  final double costPrice;
  final double salePrice;
  final int stockQuantity;
  final int minStockAlert;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.code,
    required this.costPrice,
    required this.salePrice,
    required this.stockQuantity,
    this.minStockAlert = 5,
    this.imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get profit => salePrice - costPrice;
  double get profitMargin => costPrice > 0 ? (profit / costPrice) * 100 : 0;
  bool get isLowStock => stockQuantity <= minStockAlert;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'code': code,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'stock_quantity': stockQuantity,
      'min_stock_alert': minStockAlert,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
      category: map['category'],
      code: map['code'],
      costPrice: (map['cost_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      stockQuantity: map['stock_quantity'],
      minStockAlert: map['min_stock_alert'] ?? 5,
      imagePath: map['image_path'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? brand,
    String? category,
    String? code,
    double? costPrice,
    double? salePrice,
    int? stockQuantity,
    int? minStockAlert,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      code: code ?? this.code,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

const List<String> kProductBrands = [
  'Avon',
  'Natura',
  'Eudora',
  'O Boticário',
  'Mary Kay',
  'Jequiti',
  'Hinode',
  'Amway',
  'Herbalife',
  'Racco',
  'Outra',
];

const List<String> kProductCategories = [
  'Perfume',
  'Maquiagem',
  'Skincare',
  'Cabelos',
  'Corpo',
  'Desodorante',
  'Protetor Solar',
  'Infantil',
  'Masculino',
  'Outro',
];
