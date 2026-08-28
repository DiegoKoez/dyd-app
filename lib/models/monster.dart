/// A monster/enemy the Dungeon Master can add to an encounter.
class Monster {
  final String id;
  final String name;
  final String description;
  final int maxHp;
  final int armorClass;
  final String attackName;
  final String damageDice;
  final String? photoBase64;
  final int quantity;

  const Monster({
    required this.id,
    required this.name,
    required this.description,
    required this.maxHp,
    required this.armorClass,
    required this.attackName,
    required this.damageDice,
    this.photoBase64,
    this.quantity = 1,
  });

  Monster copyWith({
    String? id,
    String? name,
    String? description,
    int? maxHp,
    int? armorClass,
    String? attackName,
    String? damageDice,
    String? photoBase64,
    int? quantity,
  }) =>
      Monster(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        maxHp: maxHp ?? this.maxHp,
        armorClass: armorClass ?? this.armorClass,
        attackName: attackName ?? this.attackName,
        damageDice: damageDice ?? this.damageDice,
        photoBase64: photoBase64 ?? this.photoBase64,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'maxHp': maxHp,
        'armorClass': armorClass,
        'attackName': attackName,
        'damageDice': damageDice,
        if (photoBase64 != null) 'photoBase64': photoBase64,
        if (quantity > 1) 'quantity': quantity,
      };

  factory Monster.fromJson(Map<String, dynamic> json) => Monster(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Sin nombre',
        description: json['description'] as String? ?? '',
        maxHp: (json['maxHp'] as num?)?.toInt() ?? 0,
        armorClass: (json['armorClass'] as num?)?.toInt() ?? 0,
        attackName: json['attackName'] as String? ?? '',
        damageDice: json['damageDice'] as String? ?? '',
        photoBase64: json['photoBase64'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Monster && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
