import 'package:analyzer/dart/element/element.dart';
import 'package:secdart_analyzer/sec_analyzer.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/annotations/parser_element.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:secdart_analyzer/src/security_type.dart';

//TODO: Implement using a DSL for aspects.
class ExternalLibraryAnnotations {
  static SecurityType getSecTypeForFunction(
      FunctionElement function, SecurityElementResolver resolver) {
    final inUseLattice = resolver.lattice;
    if (function.name == "print")
      return new SecurityFunctionTypeImpl.forExternalFunction(
          new LowLabel(),
          [
            new InterfaceSecurityTypeImpl.forExternalClass(inUseLattice.bottom,
                resolver.fromDartType(function.parameters.first.type))
          ],
          new DynamicSecurityTypeImpl(inUseLattice.bottom),
          inUseLattice.bottom);

    //TODO: improve this
    return new SecurityFunctionTypeImpl.forExternalFunction(
        inUseLattice.dynamic,
        new List<SecurityType>(),
        new DynamicSecurityTypeImpl(inUseLattice.dynamic),
        inUseLattice.dynamic);
  }
}
