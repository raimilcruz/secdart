import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';

/**
 * Represents a security type for a [InterfaceType] (eg. a class)
 */
class InterfaceSecurityTypeImpl extends InterfaceSecurityType {
  InterfaceType classType;
  ClassSecurityInfo classSecurityInfo;
  SecurityLabel _label;
  bool _isExternalClass = false;

  bool get isExternalClass => _isExternalClass;

  /**
   * Use this constructor for custom defined classes (with security concerns)
   */
  InterfaceSecurityTypeImpl(
      this._label, this.classType, this.classSecurityInfo);

  /**
   * Use this factory method for library classes (that were programmed without
   * security concerns)
   */
  InterfaceSecurityTypeImpl.forExternalClass(
      this._label, InterfaceType this.classType) {
    _isExternalClass = true;
    classSecurityInfo = new ClassSecurityInfo({}, {}, {});
  }

  @override
  SecurityLabel get label => _label;

  @override
  SecurityType stampLabel(SecurityLabel label) {
    return isExternalClass
        ? new InterfaceSecurityTypeImpl.forExternalClass(
            _label.join(label), classType)
        : new InterfaceSecurityTypeImpl(
            _label.join(label), classType, classSecurityInfo);
  }

  @override
  SecurityFunctionType getMethodSecurityType(String name) {
    if (!classSecurityInfo.methods.containsKey(name)) {
      var method = classType.lookUpInheritedMethod(name);
      SecurityFunctionType methodSecType =
          _methodOrConstructorSecurityType(method);
      classSecurityInfo.methods.putIfAbsent(name, () => methodSecType);
    }
    return classSecurityInfo.methods[name];
  }

  @override
  SecurityType getFieldSecurityType(String accessorName) {
    if (!classSecurityInfo.accessors.containsKey(accessorName)) {
      final fieldSecType = _fieldSecurityType(accessorName);
      classSecurityInfo.accessors.putIfAbsent(accessorName, () => fieldSecType);
    }
    return classSecurityInfo.accessors[accessorName];
  }

  @override
  SecurityFunctionType getConstructorSecurityType(
      String constructorName, LibraryElement library) {
    var lookupName = constructorName == "" ? null : constructorName;
    if (!classSecurityInfo.constructors.containsKey(constructorName)) {
      var constructor = classType.lookUpConstructor(lookupName, library);
      final fieldSecType = _methodOrConstructorSecurityType(constructor);
      classSecurityInfo.constructors
          .putIfAbsent(constructorName, () => fieldSecType);
    }
    return classSecurityInfo.constructors[constructorName];
  }

  SecurityFunctionType _methodOrConstructorSecurityType(
      FunctionTypedElement element) {
    var parameterSecTypes = new List<SecurityType>();
    for (ParameterElement p in element.parameters) {
      if (p.type is InterfaceType) {
        parameterSecTypes.add(new InterfaceSecurityTypeImpl.forExternalClass(
            _label.lattice.top, p.type));
      }
      if (p.type is FunctionType) {
        //TODO: fix this
        parameterSecTypes.add(new DynamicSecurityType(_label.lattice.top));
      }
    }

    SecurityLabel returnLabel = _label.lattice.bottom;

    SecurityType returnType = new DynamicSecurityType(returnLabel);
    if (element.returnType is FunctionType) {
      //TODO: fix this
      returnType = new DynamicSecurityType(returnLabel);
    }
    if (element.returnType is InterfaceType) {
      returnType = new InterfaceSecurityTypeImpl.forExternalClass(
          returnLabel, element.returnType);
    }
    return new SecurityFunctionTypeImpl(
        _label.lattice.top, parameterSecTypes, returnType, returnLabel);
  }

  SecurityType _fieldSecurityType(String fieldName) {
    //PropertyAccessorElement property =
    //    classType.lookUpInheritedGetter(fieldName);

    return new DynamicSecurityType(_label.lattice.bottom);
  }

  @override
  String toString() {
    return "${classType!=null?classType.name:"CLASS"}@$_label";
  }

  @override
  SecurityType downgradeLabel(SecurityLabel label) {
    return isExternalClass
        ? new InterfaceSecurityTypeImpl.forExternalClass(label, classType)
        : new InterfaceSecurityTypeImpl(label, classType, classSecurityInfo);
  }
}

class ClassSecurityInfo {
  Map<String, SecurityFunctionType> methods;
  Map<String, SecurityType> accessors;
  Map<String, SecurityFunctionType> constructors;
  ClassSecurityInfo(this.methods, this.accessors, this.constructors);
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

  @override
  SecurityType downgradeLabel(SecurityLabel label) {
    return new SecurityFunctionTypeImpl(
        _beginLabel, _argumentTypes, _returnType, label);
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
    return new DynamicSecurityType(this._label.join(label));
  }

  @override
  String toString() {
    return "Dyn@$_label";
  }

  @override
  SecurityType downgradeLabel(SecurityLabel label) {
    return new DynamicSecurityType(label);
  }
}
