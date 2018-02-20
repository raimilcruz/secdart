import 'package:analyzer/dart/element/element.dart';

import 'security_label.dart';

/**
 * A security type in SecDart.
 */
abstract class SecurityType {
  SecurityType();

  SecurityLabel get label;
  SecurityType stampLabel(SecurityLabel label);

  SecurityType downgradeLabel(SecurityLabel label);
}

abstract class InterfaceSecurityType extends SecurityType {
  SecurityFunctionType getMethodSecurityType(String methodName);
  SecurityType getFieldSecurityType(String fieldName);
  SecurityFunctionType getConstructorSecurityType(
      String constructorName, LibraryElement library);
}

abstract class SecurityFunctionType extends SecurityType {
  SecurityLabel get beginLabel;
  List<SecurityType> get argumentTypes;
  SecurityType get returnType;
  SecurityLabel get endLabel;
}

/**
 * The name of the property that we use to store the security type of
 * an [AstNode]
 */
const String SEC_TYPE_PROPERTY = "sec-type";
