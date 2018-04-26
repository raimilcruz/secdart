/*
This file contains the annotations that represents labels in a flat lattice of security
(BOT < LOW < HIGH < TOP)
*/

const high = const High();
const low = const Low();
const top = const Top();
const bot = const Bot();
const dynl = const DynLabel();

/**
 * Represents a high confidentiality label
 */
class High {
  const High();
}

/**
 * Represents a low confidentiality label
 */
class Low {
  const Low();
}

/**
 * Represents the top in the lattice
 */
class Top {
  const Top();
}

/**
 * Represents the bottom in the lattice
 */
class Bot {
  const Bot();
}

/**
 * Represents the dynamic label
 */
class DynLabel {
  const DynLabel();
}
