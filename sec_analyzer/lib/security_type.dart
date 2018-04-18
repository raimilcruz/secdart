import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import 'security_label.dart';

/**
 * A security type in SecDart.
 */
abstract class SecurityType {
  ///Gets the [SecurityLabel] of this type
  SecurityLabel get label;

  ///Sets the [SecurityLabel] of this type
  void set label(SecurityLabel theLabel);

  ///"Stamps" a security label to the type.
  ///stamp(T@l,l1) = T@{l v l1}
  SecurityType stampLabel(SecurityLabel label);

  ///Downgrades the security label of this type
  SecurityType downgradeLabel(SecurityLabel label);
}

/**
 * The security type for [InterfaceType] in class.
 */
abstract class InterfaceSecurityType extends SecurityType {
  /**
   * Indicates if the class was no defined in a SecDart file.
   */
  bool get isExternalClass;
  SecurityFunctionType getMethodSecurityType(String methodName);
  SecurityFunctionType getGetterSecurityType(String getterName);
  SecurityFunctionType getConstructorSecurityType(
      String constructorName, LibraryElement library);
}

/**
 * The security type for Dart function types.
 */
abstract class SecurityFunctionType extends SecurityType {
  /**
   * Indicates if the function was no defined in a SecDart file.
   */
  bool get isExternalFunction;
  SecurityLabel get beginLabel;
  List<SecurityType> get argumentTypes;
  SecurityType get returnType;
  SecurityLabel get endLabel;
}

abstract class DynamicSecurityType extends SecurityType {}

/**
 * A [PreSecurityType] can be seen as [SecurityType] before to use it
 * with a label. When we "attach" the label is is the moment
 * where a [SecurityType] is created.
 */
abstract class PreSecurityType {
  SecurityType toSecurityType(SecurityLabel label);
}

///Defines an [InterfaceType] with security notions
abstract class PreInterfaceType extends PreSecurityType {
  SecurityClassElement get securityElement;
}

///Defines a [FunctionType] with security notions
abstract class PreFunctionType extends PreSecurityType {
  SecurityLabel get beginLabel;
  List<SecurityType> get argumentTypes;
  SecurityType get returnType;
  SecurityLabel get endLabel;
}

abstract class PreDynamicType extends PreSecurityType {}

/**
 * The name of the property that we use to store the security type of
 * an [AstNode]
 */
const String SEC_TYPE_PROPERTY = "sec-type";

/**
 * The name of the property we use to store the pc at relevant nodee
 */
const String SEC_PC_PROPERTY = "sec-pc";

/**
 * The name of the property that we use to store the security element
 * of an [AstNode]
 */
const String SECURITY_ELEMENT = "sec-element";

/**
 * The security element model
 */
abstract class SecurityElement {
  /**
   * The Dart Analyzer element
   */
  Element get element;

  /**
   * Indicates whether or not the SecurityElement
   * was defined in a SecDart file
   */
  bool get isDefinedInSecDart;
}

/**
 * An element that represents a class with security notions.
 */
abstract class SecurityClassElement extends SecurityElement {
  InterfaceType get classType;
  SecurityFunctionType getMethodSecurityType(String methodName);
  SecurityMethodElement lookUpInheritedMethod(
      String methodName, LibraryElement library);
}

/**
 * An element that represents a method with security notions
 */
abstract class SecurityMethodElement extends SecurityElement {
  MethodElement get methodElement;
  SecurityFunctionType get methodType;
}

/// An element that represents a constructor with security notions
abstract class SecurityConstructorElement extends SecurityElement {
  ConstructorElement get constructorElement;
  SecurityFunctionType get constructorType;
}

/// An element that represents represents a property with security notions
abstract class SecurityPropertyAccessorElement extends SecurityElement {
  PropertyAccessorElement get propertyElement;
  SecurityType get propertyType;
}

/// An element that represents a named function with security notions
abstract class SecurityFunctionElement extends SecurityElement {
  FunctionElement get functionElement;
  SecurityFunctionType get functionType;
}

/// An element that represents a parameter with security notions
abstract class SecurityParameterElement extends SecurityElement {}

/// An element that represents a local variable with security notions
abstract class SecurityLocalVariableElement extends SecurityElement {}
