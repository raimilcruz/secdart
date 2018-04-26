import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/annotations/parser_element.dart';

/**
 * Represents a security type for a [InterfaceType] (eg. a class)
 */
class InterfaceSecurityTypeImpl extends InterfaceSecurityType {
  SecurityClassElementImpl securityElement;
  PreInterfaceType _preSecurityType;
  SecurityLabel _label;
  bool _isExternalClass = false;

  @override
  bool get isExternalClass => _isExternalClass;

  /**
   * Use this constructor for custom defined classes (with security concerns)
   */
  InterfaceSecurityTypeImpl(
      this._label, PreInterfaceType preSecurityInterfaceType) {
    _preSecurityType = preSecurityInterfaceType;
    securityElement = _preSecurityType.securityElement;
  }

  /**
   * Use this factory method for library classes (that were programmed without
   * security concerns)
   */
  InterfaceSecurityTypeImpl.forExternalClass(
      this._label, PreInterfaceType preSecurityInterfaceType) {
    _isExternalClass = true;
    _preSecurityType = preSecurityInterfaceType;
    securityElement = _preSecurityType.securityElement;
  }

  /**
   * For this class internal usage.
   */
  InterfaceSecurityTypeImpl._forExternalClass(
      this._label, SecurityClassElement element) {
    _isExternalClass = true;
    securityElement = element;
  }

  @override
  SecurityLabel get label => _label;

  @override
  SecurityType stampLabel(SecurityLabel label) {
    return isExternalClass
        ? new InterfaceSecurityTypeImpl._forExternalClass(
            _label.join(label), securityElement)
        : new InterfaceSecurityTypeImpl(_label.join(label), _preSecurityType);
  }

  @override
  SecurityFunctionType getMethodSecurityType(String name) {
    return securityElement.getMethodSecurityType(name);
  }

  @override
  SecurityFunctionType getGetterSecurityType(String accessorName) {
    return securityElement.getGetterSecurityType(accessorName);
  }

  @override
  SecurityFunctionType getConstructorSecurityType(
      String constructorName, LibraryElement library) {
    return securityElement.getConstructorSecurityType(constructorName, library);
  }

  @override
  String toString() {
    return "${securityElement.classType != null
        ? securityElement.classType.name
        : "CLASS"}@$_label";
  }

  @override
  SecurityType downgradeLabel(SecurityLabel label) {
    return isExternalClass
        ? new InterfaceSecurityTypeImpl._forExternalClass(
            label, securityElement)
        : new InterfaceSecurityTypeImpl(label, _preSecurityType);
  }

  @override
  set label(SecurityLabel theLabel) {
    _label = theLabel;
  }
}

class SecurityClassElementImpl extends SecurityClassElement {
  /**
   * The lattice used to assign default labels
   */
  GradualLattice lattice;
  SecurityElementResolver elementResolver;
  Map<String, SecurityFunctionType> methods;
  Map<String, SecurityType> accessors;
  Map<String, SecurityFunctionType> constructors;

  InterfaceType _classType;

  SecurityClassElementImpl(
      SecurityElementResolver this.elementResolver, InterfaceType classType) {
    _classType = classType;
    lattice = elementResolver.lattice;
    methods = {};
    accessors = {};
    constructors = {};
  }

  SecurityFunctionType getConstructorSecurityType(
      String constructorName, LibraryElement library) {
    var lookupName = constructorName == "" ? null : constructorName;
    if (!constructors.containsKey(constructorName)) {
      var constructor = classType.lookUpConstructor(lookupName, library);
      var securityConstructor =
          elementResolver.getSecurityConstructor(constructor);
      final constructorSecType = securityConstructor.constructorType;
      constructors.putIfAbsent(constructorName, () => constructorSecType);
    }
    return constructors[constructorName];
  }

  @override
  SecurityFunctionType getMethodSecurityType(String name) {
    if (!methods.containsKey(name)) {
      var method = classType.lookUpInheritedMethod(name);
      final securityMethod = elementResolver.getSecurityMethod(method);
      SecurityFunctionType methodSecType = securityMethod.methodType;
      methods.putIfAbsent(name, () => methodSecType);
    }
    return methods[name];
  }

  @override
  InterfaceType get classType => _classType;

  @override
  SecurityMethodElement lookUpInheritedMethod(
      String methodName, LibraryElement library) {
    final mElement = classType.lookUpInheritedMethod(methodName,
        library: library, thisType: false);
    return mElement == null
        ? null
        : elementResolver.getSecurityMethod(mElement);
  }

  @override
  Element get element => _classType.element;

  // TODO: implement isDefinedInSecDart
  @override
  bool get isDefinedInSecDart => null;

  SecurityFunctionType getGetterSecurityType(String accessorName) {
    if (!accessors.containsKey(accessorName)) {
      var getter = classType.lookUpInheritedGetter(accessorName);
      final securityMethod =
          elementResolver.getSecurityPropertyAccessor(getter);
      SecurityFunctionType methodSecType = securityMethod.propertyType;
      methods.putIfAbsent(accessorName, () => methodSecType);
    }
    return accessors[accessorName];
  }
}

class SecurityMethodElementImpl extends SecurityMethodElement {
  MethodElement _element;
  SecurityFunctionType _methodType;

  SecurityMethodElementImpl(
      MethodElement element, SecurityFunctionType methodType) {
    _element = element;
    _methodType = methodType;
  }

  @override
  MethodElement get element => _element;

  @override
  SecurityFunctionType get methodType => _methodType;

  // TODO: implement isDefinedInSecDart
  @override
  bool get isDefinedInSecDart => null;

  @override
  MethodElement get methodElement => _element;
}

class SecurityConstructorElementImpl extends SecurityConstructorElement {
  ConstructorElement _constructorElement;
  SecurityFunctionType _constructorSecurityType;
  SecurityConstructorElementImpl(
      this._constructorElement, this._constructorSecurityType) {}

  @override
  ConstructorElement get constructorElement => _constructorElement;

  @override
  SecurityFunctionType get constructorType => _constructorSecurityType;

  @override
  Element get element => _constructorElement;

  @override
  bool get isDefinedInSecDart => throw new UnimplementedError();
}

class SecurityPropertyAccessorElementImpl
    extends SecurityPropertyAccessorElement {
  SecurityFunctionType _securityType;
  PropertyAccessorElement _element;

  SecurityPropertyAccessorElementImpl(
      PropertyAccessorElement element, SecurityFunctionType type) {
    _element = element;
    _securityType = type;
  }

  @override
  Element get element => _element;

  @override
  bool get isDefinedInSecDart => null;

  @override
  PropertyAccessorElement get propertyElement => _element;

  @override
  SecurityFunctionType get propertyType => _securityType;
}

class SecurityFunctionElementImpl extends SecurityFunctionElement {
  FunctionElement _element;
  SecurityFunctionType _functionType;

  SecurityFunctionElementImpl(
      FunctionElement element, SecurityFunctionType functionType) {
    _element = element;
    _functionType = functionType;
  }

  @override
  Element get element => _element;

  @override
  FunctionElement get functionElement => _element;

  @override
  SecurityFunctionType get functionType => _functionType;

  @override
  bool get isDefinedInSecDart => null;
}

/**
 * Represents a security type associated to [FunctionType]
 */
class SecurityFunctionTypeImpl extends SecurityFunctionType {
  SecurityType _returnType;
  List<SecurityType> _argumentTypes;
  SecurityLabel _beginLabel;
  SecurityLabel _endLabel;
  bool _isExternalFunction;

  SecurityFunctionTypeImpl(
      this._beginLabel, this._argumentTypes, this._returnType, this._endLabel);

  SecurityFunctionTypeImpl.forExternalFunction(
      this._beginLabel, this._argumentTypes, this._returnType, this._endLabel) {
    _isExternalFunction = true;
  }

  @override
  bool get isExternalFunction => isExternalFunction;

  @override
  SecurityType get returnType => _returnType;

  @override
  SecurityLabel get beginLabel => _beginLabel;

  @override
  SecurityLabel get endLabel => _endLabel;

  @override
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
    if (_isExternalFunction) {
      return new SecurityFunctionTypeImpl.forExternalFunction(
          _beginLabel, _argumentTypes, _returnType, label);
    } else {
      return new SecurityFunctionTypeImpl(
          _beginLabel, _argumentTypes, _returnType, label);
    }
  }

  @override
  set label(SecurityLabel theLabel) {
    _endLabel = theLabel;
  }
}

/**
    Represents a security type where the [DartType] is dynamic
 **/
class DynamicSecurityTypeImpl extends DynamicSecurityType {
  SecurityLabel _label;

  DynamicSecurityTypeImpl(this._label);

  @override
  SecurityLabel get label => this._label;

  @override
  SecurityType stampLabel(SecurityLabel label) {
    return new DynamicSecurityTypeImpl(this._label.join(label));
  }

  @override
  String toString() {
    return "Dyn@$_label";
  }

  @override
  SecurityType downgradeLabel(SecurityLabel label) {
    return new DynamicSecurityTypeImpl(label);
  }

  @override
  set label(SecurityLabel theLabel) {
    _label = theLabel;
  }
}

class PreInterfaceTypeImpl extends PreInterfaceType {
  SecurityClassElement _securityClassElement;
  bool _isExternalClass = false;

  PreInterfaceTypeImpl(SecurityClassElement securityClassElement) {
    _securityClassElement = securityClassElement;
  }

  PreInterfaceTypeImpl.forExternalClass(
      SecurityClassElement securityClassElement) {
    _isExternalClass = true;
    _securityClassElement = securityClassElement;
  }

  @override
  SecurityClassElement get securityElement => _securityClassElement;

  @override
  SecurityType toSecurityType(SecurityLabel label) {
    return _isExternalClass
        ? new InterfaceSecurityTypeImpl(label, this)
        : new InterfaceSecurityTypeImpl.forExternalClass(label, this);
  }
}

class PreFunctionTypeImpl extends PreFunctionType {
  SecurityLabel _beginLabel;
  List<SecurityType> _argumentTypes;
  SecurityType _returnType;

  PreFunctionTypeImpl(SecurityLabel beginLabel,
      List<SecurityType> argumentTypes, SecurityType returnType) {
    _beginLabel = beginLabel;
    _argumentTypes = argumentTypes;
    _returnType = returnType;
  }

  @override
  List<SecurityType> get argumentTypes => _argumentTypes;

  @override
  SecurityLabel get beginLabel => _beginLabel;

  @override
  SecurityLabel get endLabel => null;

  @override
  SecurityType get returnType => _returnType;

  @override
  SecurityType toSecurityType(SecurityLabel label) {
    return new SecurityFunctionTypeImpl(
        beginLabel, argumentTypes, returnType, label);
  }
}

class PreDynamicTypeImpl extends PreDynamicType {
  static final PreDynamicTypeImpl _singleton = new PreDynamicTypeImpl._();

  factory PreDynamicTypeImpl() {
    return _singleton;
  }

  PreDynamicTypeImpl._();

  @override
  SecurityType toSecurityType(SecurityLabel label) {
    return new DynamicSecurityTypeImpl(label);
  }
}

class SecurityCache {
  Map<Element, SecurityElement> map;
  //TODO: Check if we need this or a map from Element to SecurityElement.
  Map<DartType, PreSecurityType> typeCache;

  SecurityCache() {
    map = {};
    typeCache = {};
  }
}
