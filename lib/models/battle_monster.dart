/// A monster instance participating in an active battle (with live HP).
class BattleMonster {
  final String instanceId;
  final String id;
  final String name;
  final String attackName;
  final String damageDice;
  final int armorClass;
  final int maxHp;
  final int currentHp;
  final String? photoBase64;

  const BattleMonster({
    required this.instanceId,
    required this.id,
    required this.name,
    required this.attackName,
    required this.damageDice,
    required this.armorClass,
    required this.maxHp,
    required this.currentHp,
    this.photoBase64,
  });

  bool get isDefeated => currentHp <= 0;

  factory BattleMonster.fromJson(Map<String, dynamic> json) => BattleMonster(
        instanceId: json['instanceId'] as String? ?? '',
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        attackName: json['attackName'] as String? ?? '',
        damageDice: json['damageDice'] as String? ?? '',
        armorClass: (json['armorClass'] as num?)?.toInt() ?? 0,
        maxHp: (json['maxHp'] as num?)?.toInt() ?? 0,
        currentHp: (json['currentHp'] as num?)?.toInt() ?? 0,
        photoBase64: json['photoBase64'] as String?,
      );
}
