/**
 * Represents an label annotated in the code
 */
abstract class LabelNode {
  String get literalRepresentation;

  static LabelNode get noAnnotated => new NoAnnotatedLabel();
}

class NoAnnotatedLabel extends LabelNode {
  static NoAnnotatedLabel _instance = new NoAnnotatedLabel._internal();

  factory NoAnnotatedLabel() => _instance;

  NoAnnotatedLabel._internal();

  @override
  String get literalRepresentation => "";
}

/**
 * Abstract class to represent a security label
 */
abstract class SecurityLabel {
  /**
   * When is implemented in a derived class returns a boolean value indicating
   * if the current label can flow to the specific label
   */
  bool canRelabeledTo(SecurityLabel l);

  /**
   * When is implemented in a derived class returns the meet
   */
  SecurityLabel meet(SecurityLabel other);

  /**
   * When is implemented in a derived class returns the join
   */
  SecurityLabel join(SecurityLabel other);

  bool lessOrEqThan(SecurityLabel other) {
    return this.canRelabeledTo(other);
  }

  SecurityLabel substitute(
      List<String> labelParameter, List<String> securityLabels);
}

abstract class StaticLabel extends SecurityLabel {
  String get representation;
}

/**
 * Represents relevant label of the lattice
 */
abstract class GradualLattice {
  /**
   * The greatest element in the lattice
   */
  SecurityLabel get top;

  /**
   * The lowest element in the lattice
   */
  SecurityLabel get bottom;

  /**
   * The representation for the dynamic label
   */
  SecurityLabel get dynamic;

  String get dynamicLiteralRepresentation;

  SecurityLabel lift(StaticLabel staticLabelImpl);
}

/**
 * The name of the property that we use to store the security label ([LabelNode]) of
 * an [AstNode]
 */
const String SEC_LABEL_PROPERTY = "sec-label";

class LatticeConfig {
  List<String> elements;
  List<LabelOrder> order;
  String top;
  String bottom;
  String unknown;

  LatticeConfig(this.elements, this.order, this.top, this.bottom,
      [this.unknown = "?"]);

  static final LatticeConfig defaultLattice = new LatticeConfig([
    "bot",
    "L",
    "H",
    "top"
  ], [
    new LabelOrder("bot", "L"),
    new LabelOrder("L", "H"),
    new LabelOrder("H", "top")
  ], "top", "bot");
}

class LabelOrder {
  String s1, s2;

  LabelOrder(this.s1, this.s2);

  @override
  String toString() => "$s1 <= $s2";
}
