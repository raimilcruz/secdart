//
// Implementation of subtyping rules for security types
//

import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/annotations/parser_element.dart';

import 'security_type.dart';
import 'package:analyzer/dart/element/type.dart';

class GradualSecurityTypeSystem {
  String _error;
  String get error => _error;

  bool isSubtypeOf(SecurityType t1, SecurityType t2) {
    _error = "";
    if (t1 is! SecurityType || t2 is! SecurityType) {
      //throw new UnsupportedError("Operation is not supported. Both types must instance of SecurityType");
      _error =
          "Operation is not supported. Both types must instance of SecurityType";
      return false;
    }
    if (t1 is DynamicSecurityType) {
      return t1.label.canRelabeledTo(t2.label);
    }
    if (t2 is DynamicSecurityType) {
      return t1.label.canRelabeledTo(t2.label);
    }
    if (t1 is InterfaceSecurityType && t2 is InterfaceSecurityType) {
      //We assume that we work over "gradually-well-typed programs",
      //so we do not check for subtyping between the dart types
      return t1.label.canRelabeledTo(t2.label);
    }
    if (t1 is SecurityFunctionType && t2 is SecurityFunctionType) {
      SecurityFunctionType sT1 = t1;
      SecurityFunctionType sT2 = t2;

      //check subtyping for arguments
      if (!_subtype(sT2.argumentTypes, sT1.argumentTypes)) return false;
      //check subtyping for return type
      if (!isSubtypeOf(sT1.returnType, sT2.returnType)) return false;
      //check label ordering for latent effect(begin label)
      if (!sT1.endLabel.canRelabeledTo(sT2.endLabel)) return false;
      //check label ordering for return label (function label)
      if (!sT2.beginLabel.canRelabeledTo(sT1.beginLabel)) return false;

      return true;
    } else {
      _error = "$t1 is not subtype of $t2";
      return false;
    }
  }

  bool _subtype(List<SecurityType> args1, List<SecurityType> args2) {
    if (args1.length != args2.length) return false;
    for (int i = 0; i < args1.length; i++) {
      if (!isSubtypeOf(args1[i], args2[i])) return false;
    }
    return true;
  }

  SecurityType join(SecurityType s1, SecurityType s2, DartType resultHint,
      ElementAnnotationParserImpl elementParser) {
    if (s1 is DynamicSecurityType) {
      return new DynamicSecurityType(s1.label.join(s2.label));
    }
    if (s2 is DynamicSecurityType) {
      return new DynamicSecurityType(s1.label.join(s2.label));
    }
    if (s1 is InterfaceSecurityType && s2 is InterfaceSecurityType) {
      return elementParser.fromDartType(resultHint, s1.label.join(s2.label));
    }
    if (s1 is SecurityFunctionType &&
        s2 is SecurityFunctionType &&
        resultHint is FunctionType) {
      return new SecurityFunctionTypeImpl(
          s1.beginLabel.meet(s2.beginLabel),
          _meetParameters(s1.argumentTypes, s2.argumentTypes,
              resultHint.parameters.map((p) => p.type).toList(), elementParser),
          join(s1.returnType, s2.returnType, resultHint.returnType,
              elementParser),
          s1.endLabel.join(s2.endLabel));
    }
    return null;
  }

  SecurityType meet(SecurityType s1, SecurityType s2, DartType resultHint,
      ElementAnnotationParserImpl elementParser) {
    if (s1 is DynamicSecurityType) {
      return new DynamicSecurityType(s1.label.meet(s2.label));
    }
    if (s2 is DynamicSecurityType) {
      return new DynamicSecurityType(s1.label.meet(s2.label));
    }
    if (s1 is InterfaceSecurityType && s2 is InterfaceSecurityType) {
      return elementParser.fromDartType(resultHint, s1.label.meet(s2.label));
    }
    if (s1 is SecurityFunctionType &&
        s2 is SecurityFunctionType &&
        resultHint is FunctionType) {
      return new SecurityFunctionTypeImpl(
          s1.beginLabel.join(s2.beginLabel),
          _joinParameters(s1.argumentTypes, s2.argumentTypes,
              resultHint.parameters.map((p) => p.type).toList(), elementParser),
          meet(s1.returnType, s2.returnType, resultHint.returnType,
              elementParser),
          s1.endLabel.meet(s2.endLabel));
    }
    return null;
  }

  List<SecurityType> _meetParameters(
      List<SecurityType> l1,
      List<SecurityType> l2,
      List<DartType> hint,
      ElementAnnotationParserImpl elementParser) {
    if (l1.length != l2.length)
      throw new ArgumentError("Distinct argument size");
    List<SecurityType> result = [];
    for (int i = 0; i < l1.length; i++) {
      result.add(meet(l1[i], l2[i], hint[i], elementParser));
    }
    return result;
  }

  List<SecurityType> _joinParameters(
      List<SecurityType> l1,
      List<SecurityType> l2,
      List<DartType> hint,
      ElementAnnotationParserImpl elementParser) {
    if (l1.length != l2.length)
      throw new ArgumentError("Distinct argument size");
    List<SecurityType> result = [];
    for (int i = 0; i < l1.length; i++) {
      result.add(join(l1[i], l2[i], hint[i], elementParser));
    }
    return result;
  }
}
