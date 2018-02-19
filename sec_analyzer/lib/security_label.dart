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

  Lattice get lattice;

  SecurityLabel substitute(
      List<String> labelParameter, List<String> securityLabels);
}

/**
 * Represents relevant label of the lattice
 */
abstract class Lattice {
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
}
