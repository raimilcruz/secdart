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
 * Label for function annotations
 */
class latent {
  /**
   * The label required to invoke the function
   */
  final String beginLabel;

  /**
   * The label of the return value of the function can not be higher than the [endlabel]
   */
  final String endLabel;
  const latent(this.beginLabel, this.endLabel);
}

class DynLabel {
  const DynLabel();
}

/**
 * Represents a label annotation. Its interpretation is open.
 * eg. Lab("H"), Lab("Alice -> Bob")
 */
class Lab {
  final String labelRep;
  const Lab(String this.labelRep);
}
