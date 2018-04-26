import 'package:secdart_analyzer/security_label.dart';
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

  static List<String> latticeTopologicalSort() {
    return graphLattice.topSort();
  }
}
