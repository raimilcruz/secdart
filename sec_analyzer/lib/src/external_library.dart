import 'package:analyzer/dart/element/element.dart';
import 'package:secdart_analyzer/sec_analyzer.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:secdart_analyzer/src/security_type.dart';

class ExternalLibraryAnnotations {
  static SecurityType getSecTypeForFunction(
      FunctionElement function, Lattice inUseLattice) {
    if (function.name == "print")
      return new SecurityFunctionTypeImpl(
          new LowLabel(),
          [
            new InterfaceSecurityTypeImpl.forExternalClass(
                inUseLattice.bottom, function.parameters.first.type)
          ],
          new DynamicSecurityType(inUseLattice.bottom),
          inUseLattice.bottom);

    //TODO: improve this
    return new SecurityFunctionTypeImpl(
        inUseLattice.dynamic,
        new List<SecurityType>(),
        new DynamicSecurityType(inUseLattice.dynamic),
        inUseLattice.dynamic);
  }

  static SecurityType securityTypeForDartType() {
    return null;
  }
}
