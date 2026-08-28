/// The six core ability scores used by every character.
enum Ability { fuerza, destreza, constitucion, inteligencia, sabiduria, carisma }

extension AbilityLabels on Ability {
  String get label {
    switch (this) {
      case Ability.fuerza:
        return 'Fuerza';
      case Ability.destreza:
        return 'Destreza';
      case Ability.constitucion:
        return 'Constitución';
      case Ability.inteligencia:
        return 'Inteligencia';
      case Ability.sabiduria:
        return 'Sabiduría';
      case Ability.carisma:
        return 'Carisma';
    }
  }

  String get abbreviation {
    switch (this) {
      case Ability.fuerza:
        return 'FUE';
      case Ability.destreza:
        return 'DES';
      case Ability.constitucion:
        return 'CON';
      case Ability.inteligencia:
        return 'INT';
      case Ability.sabiduria:
        return 'SAB';
      case Ability.carisma:
        return 'CAR';
    }
  }
}
