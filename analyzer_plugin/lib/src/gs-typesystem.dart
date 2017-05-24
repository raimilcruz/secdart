//
// Implementation of subtyping rules for security types 
//

import 'package:secdart_analyzer_plugin/src/error-collector.dart';
import 'security-type.dart';

//TODO: Checks if it is convinient to inherit from the TypeSystem class from analyzer package
class GradualSecurityTypeSystem {
  String _error;
  String get error => _error;

  bool isSubtypeOf(SecurityType t1, SecurityType t2) {
    _error  = "";
    // TODO: improve this implementation.
    // TODO: Add cases for function types (begin-label, end-label)
    if(t1 is! SecurityType || t2 is! SecurityType){
      //throw new UnsupportedError("Operation is not supported. Both types must instance of SecurityType");
      _error = "Operation is not supported. Both types must instance of SecurityType";
      return false;
    }
    if((t1 is GroundSecurityType && t2 is GroundSecurityType)){
      GroundSecurityType sT1 = t1 as GroundSecurityType;
      GroundSecurityType sT2 = t2 as GroundSecurityType;

      if(sT1.internalType.isSubtypeOf(sT2.internalType)){
        return sT1.label.canRelabeledTo(sT2.label);
      }
      return false;
    }
    else{
      //TODO: Implement for high-order types
      //throw new UnimplementedError("GradualSecurityTypeSystem.isSubtypeOf");
      _error = "SecurityGradualTypeSystem.isSubtypeOf is not implemented for high-order security types";
      return false;
    }
  }
}
