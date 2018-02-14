import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'security_label.dart';

/**
 * A security type in SecDart.
 */
abstract class SecurityType {
  SecurityType();

  SecurityLabel get label;
  SecurityType stampLabel(SecurityLabel label);

  SecurityType join(SecurityType other);
  SecurityType meet(SecurityType other);
}

abstract class InterfaceSecurityType extends SecurityType {
  SecurityFunctionType getMethodSecurityType(String name);
}

abstract class SecurityFunctionType extends SecurityType {
  SecurityLabel get beginLabel;
  List<SecurityType> get argumentTypes;
  SecurityType get returnType;
  SecurityLabel get endLabel;
}

/**
 * Represents a security type for a [InterfaceType] (eg. a class)
 */
class InterfaceSecurityTypeImpl extends InterfaceSecurityType {
  ClassElement classElement;
  ClassSecurityInfo classSecurityInfo;
  SecurityLabel _label;
  InterfaceSecurityTypeImpl(this._label, this.classSecurityInfo);
  @override
  SecurityLabel get label => _label;

  @override
  SecurityType stampLabel(SecurityLabel label) {
    return new InterfaceSecurityTypeImpl(_label.join(label), classSecurityInfo);
  }

  SecurityFunctionType getMethodSecurityType(String name) {
    return classSecurityInfo.methods[name];
  }

  @override
  SecurityType join(SecurityType other) {
    // TODO: implement join
    throw new Exception("Not implemented yet");
  }

  @override
  SecurityType meet(SecurityType other) {
    // TODO: implement meet
    throw new Exception("Not implemented yet");
  }
}

class ClassSecurityInfo {
  Map<String, SecurityFunctionType> methods;
  ClassSecurityInfo(this.methods);
}

/**
 * Represents a security type for "builtin types" (eg. Int, Bool)
 */
class GroundSecurityType extends SecurityType {
  SecurityLabel _label;
  GroundSecurityType(this._label);

  @override
  SecurityLabel get label => this._label;

  @override
  SecurityType stampLabel(SecurityLabel label) {
    return new GroundSecurityType(this._label.join(label));
  }

  @override
  String toString() {
    return "$_label";
  }

  @override
  SecurityType join(SecurityType other) {
    if (!(other is GroundSecurityType))
      throw new ArgumentError("Expected argument of type GroundSecurityType");
    return new GroundSecurityType(_label.join(other.label));
  }

  @override
  SecurityType meet(SecurityType other) {
    if (!(other is GroundSecurityType))
      throw new ArgumentError("Expected argument of type GroundSecurityType");
    return new GroundSecurityType(_label.meet(other.label));
  }
}

/**
 * Represents a security type associated to [FunctionType]
 */
class SecurityFunctionTypeImpl extends SecurityFunctionType {
  SecurityType _returnType;
  List<SecurityType> _argumentTypes;
  SecurityLabel _beginLabel;
  SecurityLabel _endLabel;
  SecurityFunctionTypeImpl(
      this._beginLabel, this._argumentTypes, this._returnType, this._endLabel);

  SecurityType get returnType => _returnType;
  SecurityLabel get beginLabel => _beginLabel;
  SecurityLabel get endLabel => _endLabel;
  List<SecurityType> get argumentTypes => _argumentTypes;

  @override
  SecurityLabel get label => _endLabel;
  @override
  SecurityType stampLabel(SecurityLabel label) {
    return new SecurityFunctionTypeImpl(
        _beginLabel, _argumentTypes, _returnType, _endLabel.join(label));
  }

  String toString() {
    return "($argumentTypes->[$_beginLabel]->$_returnType)@$_endLabel";
  }

  SecurityType join(SecurityType other) {
    if (!(other is SecurityFunctionType))
      throw new ArgumentError("Expected argument of type SecurityFunctionType");
    SecurityFunctionType otherSecFunType = other;
    return new SecurityFunctionTypeImpl(
        beginLabel.meet(otherSecFunType.beginLabel),
        _meetParameters(argumentTypes, otherSecFunType.argumentTypes),
        returnType.join(otherSecFunType.returnType),
        endLabel.join(otherSecFunType.endLabel));
  }

  @override
  SecurityType meet(SecurityType other) {
    if (!(other is SecurityFunctionType))
      throw new ArgumentError("Expected argument of type SecurityFunctionType");
    SecurityFunctionType otherSecFunType = other;
    return new SecurityFunctionTypeImpl(
        beginLabel.join(otherSecFunType.beginLabel),
        _joinParameters(argumentTypes, otherSecFunType.argumentTypes),
        returnType.meet(otherSecFunType.returnType),
        endLabel.meet(otherSecFunType.endLabel));
  }

  List<SecurityType> _meetParameters(
      List<SecurityType> l1, List<SecurityType> l2) {
    if (l1.length != l2.length)
      throw new ArgumentError("Distinct argument size");
    List<SecurityType> result = [];
    for (int i = 0; i < l1.length; i++) {
      result.add(l1[i].meet(l2[i]));
    }
    return result;
  }

  List<SecurityType> _joinParameters(
      List<SecurityType> l1, List<SecurityType> l2) {
    if (l1.length != l2.length)
      throw new ArgumentError("Distinct argument size");
    List<SecurityType> result = [];
    for (int i = 0; i < l1.length; i++) {
      result.add(l1[i].join(l2[i]));
    }
    return result;
  }
}

/**
Represents a security type where the [DartType] is dynamic
 **/
class DynamicSecurityType extends SecurityType {
  SecurityLabel _label;
  DynamicSecurityType(this._label);

  @override
  SecurityLabel get label => this._label;

  @override
  SecurityType stampLabel(SecurityLabel label) {
    return new GroundSecurityType(this._label.join(label));
  }

  @override
  String toString() {
    return "$_label";
  }

  @override
  SecurityType join(SecurityType other) {
    if (!(other is DynamicSecurityType))
      throw new ArgumentError("Expected argument of type DynamicSecurityType");
    return new DynamicSecurityType(label.join(other.label));
  }

  @override
  SecurityType meet(SecurityType other) {
    if (!(other is DynamicSecurityType))
      throw new ArgumentError("Expected argument of type DynamicSecurityType");
    return new DynamicSecurityType(label.meet(other.label));
  }
}
