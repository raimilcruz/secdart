//
// Implementation of subtyping rules for security types
//

import 'security_type.dart';

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
    if (t1 is GroundSecurityType && t2 is GroundSecurityType) {
      GroundSecurityType sT1 = t1;
      GroundSecurityType sT2 = t2;

      //We assume that we work over "gradually-well-typed programs",
      //so we do not check for subtyping between the dart types
      return sT1.label.canRelabeledTo(sT2.label);
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
}
