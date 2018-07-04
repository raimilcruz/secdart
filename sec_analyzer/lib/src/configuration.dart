import 'package:secdart_analyzer/src/options.dart';
import 'package:secdart_analyzer/src/security_label.dart';

///Configuration options for the analysis, for extensions to the analysis.
///eg. to support a different lattice.
class SecDartConfig {
  static final SecDartConfig instance = new SecDartConfig._();

  factory SecDartConfig() => instance;

  SecDartConfig._();

  static GraphLattice graphLattice;

  //call this to configure the label
  static init(LatticeConfig customLattice) {
    graphLattice =
        new GraphLattice(customLattice.elements, customLattice.order);
  }

  static bool isLessOrEqualThan(String s1, String s2) =>
      graphLattice.isLessOrEqualThan(s1, s2);

  static String meet(String s1, String s2) => graphLattice.meet(s1, s2);

  static String join(String s1, String s2) => graphLattice.join(s1, s2);
}
