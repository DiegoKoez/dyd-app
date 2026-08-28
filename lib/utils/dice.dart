/// Rolls a dice expression like "1d6" or "2d10" and returns the total.
library;

import 'dart:math';

int rollDice(String dice) {
  final match = RegExp(r'^(\d+)d(\d+)$').firstMatch(dice.trim());
  if (match == null) return 1;
  final count = int.parse(match.group(1)!);
  final sides = int.parse(match.group(2)!);
  final random = Random();
  var total = 0;
  for (var i = 0; i < count; i++) {
    total += random.nextInt(sides) + 1;
  }
  return total;
}
