import 'package:flutter/material.dart';

/// An item the Dungeon Master can create/give to a player (poción, veneno,
/// hielo, cuerda, etc.). The [effect] is a simple tag used for the icon and
/// for future rules (damage over time, status effects...).
class GameItem {
  final String id;
  final String name;
  final String description;
  final String effect;
  final String? damageDice;
  final String? icon;
  final String? imageBase64;

  const GameItem({
    required this.id,
    required this.name,
    required this.description,
    required this.effect,
    this.damageDice,
    this.icon,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'effect': effect,
        'damageDice': damageDice,
        'icon': icon,
        'imageBase64': imageBase64,
      };

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        effect: json['effect'] as String,
        damageDice: json['damageDice'] as String?,
        icon: json['icon'] as String?,
        imageBase64: json['imageBase64'] as String?,
      );

  GameItem copyWith({
    String? id,
    String? name,
    String? description,
    String? effect,
    String? damageDice,
    String? icon,
    String? imageBase64,
  }) {
    return GameItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      effect: effect ?? this.effect,
      damageDice: damageDice ?? this.damageDice,
      icon: icon ?? this.icon,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}

IconData iconForEffect(String effect) {
  switch (effect) {
    case 'curacion':
      return Icons.favorite;
    case 'veneno':
      return Icons.science;
    case 'hielo':
      return Icons.ac_unit;
    case 'fuego':
      return Icons.local_fire_department;
    case 'fogata':
      return Icons.outdoor_grill;
    case 'comida':
      return Icons.restaurant;
    default:
      return Icons.inventory_2;
  }
}

String emojiForItemName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('anillo')) return '💍';
  if (lower.contains('cuerda')) return '🪢';
  if (lower.contains('poción') || lower.contains('pocion')) return '🧪';
  if (lower.contains('espada')) return '⚔️';
  if (lower.contains('arco')) return '🏹';
  if (lower.contains('escudo')) return '🛡️';
  if (lower.contains('armadura') || lower.contains('armadura')) return '🦺';
  if (lower.contains('casco') || lower.contains('sombrero')) return '👑';
  if (lower.contains('botas')) return '👢';
  if (lower.contains('anillo')) return '💍';
  if (lower.contains('poción') || lower.contains('pocion')) return '🧪';
  if (lower.contains('comida') || lower.contains('pan') || lower.contains('fruta')) return '🍎';
  if (lower.contains('llave') || lower.contains('llave')) return '🔑';
  if (lower.contains('mapa')) return '🗺️';
  if (lower.contains('libro') || lower.contains('grimorio')) return '📕';
  if (lower.contains('oro') || lower.contains('dinero') || lower.contains('moneda')) return '💰';
  if (lower.contains('gema') || lower.contains('piedra')) return '💎';
  if (lower.contains('varita') || lower.contains('bastón') || lower.contains('baston')) return '🪄';
  if (lower.contains('fuego') || lower.contains('llama')) return '🔥';
  if (lower.contains('hielo') || lower.contains('escarcha') || lower.contains('frio')) return '❄️';
  if (lower.contains('veneno') || lower.contains('ponzoña')) return '☠️';
  if (lower.contains('cuerda') || lower.contains('soga')) return '🪢';
  if (lower.contains('martillo')) return '🔨';
  if (lower.contains('hacha')) return '🪓';
  if (lower.contains('daga') || lower.contains('cuchillo')) return '🗡️';
  if (lower.contains('lanza')) return '🔱';
  if (lower.contains('arco')) return '🏹';
  if (lower.contains('flecha')) return '➳';
  if (lower.contains('trébol') || lower.contains('trebol') || lower.contains('suerte')) return '🍀';
  if (lower.contains('corona')) return '👑';
  if (lower.contains('antorcha')) return '🔦';
  if (lower.contains('bola') || lower.contains('cristal')) return '🔮';
  if (lower.contains('reloj') || lower.contains('arena')) return '⏳';
  if (lower.contains('calavera')) return '💀';
  if (lower.contains('ala') || lower.contains('pluma')) return '🪶';
  if (lower.contains('dado')) return '🎲';
  if (lower.contains('carta') || lower.contains('baraja')) return '🃏';
  if (lower.contains('pergamino') || lower.contains('nota')) return '📜';
  if (lower.contains('poción') || lower.contains('pocion')) return '🧪';
  if (lower.contains('venda') || lower.contains('vendaje')) return '🩹';
  if (lower.contains('antídoto') || lower.contains('antidoto')) return '💉';
  if (lower.contains('cuerda')) return '🪢';
  if (lower.contains('anillo')) return '💍';
  return '🎁';
}
