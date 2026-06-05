class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final String productBrand;
  final double unitPrice;
  final double costPrice;
  final int quantity;
  final double discount;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.productBrand,
    required this.unitPrice,
    required this.costPrice,
    required this.quantity,
    this.discount = 0,
  });

  double get totalPrice => (unitPrice * quantity) - discount;
  double get totalCost => costPrice * quantity;
  double get totalProfit => totalPrice - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'product_brand': productBrand,
      'unit_price': unitPrice,
      'cost_price': costPrice,
      'quantity': quantity,
      'discount': discount,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      productBrand: map['product_brand'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      quantity: map['quantity'],
      discount: (map['discount'] as num).toDouble(),
    );
  }
}
