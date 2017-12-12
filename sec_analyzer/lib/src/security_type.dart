import 'package:analyzer/dart/element/type.dart';
import 'security_label.dart';


abstract class SecurityType{
  SecurityType();

  SecurityLabel get label;
  SecurityType stampLabel(SecurityLabel label);
}

class GroundSecurityType extends SecurityType {
  SecurityLabel _label;
  DartType internalType;

  GroundSecurityType(this.internalType, this._label);


  @override
  SecurityLabel get label => this._label;

  @override
  SecurityType stampLabel(SecurityLabel label) {
    return new GroundSecurityType(this.internalType,this._label.join(label));
  }
  @override
  String toString(){
    return "$internalType@$_label";
  }
}

class SecurityFunctionType extends SecurityType {
  SecurityType _returnType;
  List<SecurityType> _argumentTypes;
  SecurityLabel _beginLabel;
  SecurityLabel _endLabel;
  SecurityFunctionType(this._beginLabel,this._argumentTypes,this._returnType,this._endLabel);


  SecurityType get returnType => _returnType;
  SecurityLabel get beginLabel => _beginLabel;
  SecurityLabel get endLabel => _endLabel;
  List<SecurityType> get argumentTypes => _argumentTypes;


  @override
  SecurityLabel get label => _endLabel;
  @override
  SecurityType stampLabel(SecurityLabel label) {
    return new SecurityFunctionType(_beginLabel, _argumentTypes, _returnType, _endLabel.join(label));
  }

  String toString(){
    return "($argumentTypes->[$_beginLabel]->$_returnType)@$_endLabel";
  }
}

