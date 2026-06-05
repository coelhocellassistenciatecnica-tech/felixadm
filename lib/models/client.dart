class Client {
  final int? id;
  final String name;
  final String phone;
  final String? whatsapp;
  final String? address;
  final String? neighborhood;
  final String? city;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    this.id,
    required this.name,
    required this.phone,
    this.whatsapp,
    this.address,
    this.neighborhood,
    this.city,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'address': address,
      'neighborhood': neighborhood,
      'city': city,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      whatsapp: map['whatsapp'],
      address: map['address'],
      neighborhood: map['neighborhood'],
      city: map['city'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? whatsapp,
    String? address,
    String? neighborhood,
    String? city,
    String? notes,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      address: address ?? this.address,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
