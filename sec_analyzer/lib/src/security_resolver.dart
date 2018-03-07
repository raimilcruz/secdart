import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/annotations/parser_element.dart';
import 'package:secdart_analyzer/src/external_library.dart';
import 'package:secdart_analyzer/src/gs_typesystem.dart';
import 'package:secdart_analyzer/src/helper.dart';
import 'package:secdart_analyzer/src/security_visitor.dart';

import 'errors.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import 'security_type.dart';

/**
 * This visitor resolves the security types for every supported expression
 *
 * It basically computes labels for expressions.
 */
class SecurityResolverVisitor extends AbstractSecurityVisitor {
  ElementAnnotationParserImpl _elementParser;
  GradualSecurityTypeSystem typeSystem;

  SecurityResolverVisitor(
      AnalysisErrorListener reporter, ElementAnnotationParserImpl elementParser,
      [bool intervalMode = false])
      : super(reporter) {
    _elementParser = elementParser;
    typeSystem = new GradualSecurityTypeSystem();
    pc = _elementParser.lattice.dynamic;
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    //visit the if node
    node.condition.accept(this);
    var conditionalSecType = getSecurityType(node.condition);
    //increase the pc
    var currentPc = pc;
    pc = pc.join(conditionalSecType.label);

    //visit both branches
    node.thenExpression.accept(this);

    node.elseExpression.accept(this);

    final secTypeThenExpr = getSecurityType(node.thenExpression);
    final secTypeElseExpr = getSecurityType(node.elseExpression);

    SecurityType resultType = typeSystem
        .join(secTypeThenExpr, secTypeElseExpr, node.bestType, _elementParser)
        .stampLabel(conditionalSecType.label);

    node.setProperty(SEC_TYPE_PROPERTY, resultType);
    pc = currentPc;

    return true;
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    node.setProperty(SEC_TYPE_PROPERTY,
        new InterfaceSecurityTypeImpl.forExternalClass(pc, node.bestType));
    return true;
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    node.setProperty(SEC_TYPE_PROPERTY,
        new InterfaceSecurityTypeImpl.forExternalClass(pc, node.bestType));
    return true;
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    //this method is call for any string literal including import uris,
    //and annotations arguments which are not relevant for the security analysis.
    //By checking the pc!=null we avoid to process those nodes.
    if (pc != null) {
      node.setProperty(SEC_TYPE_PROPERTY,
          new InterfaceSecurityTypeImpl.forExternalClass(pc, node.bestType));
    }
    return true;
  }

  @override
  bool visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
    SecurityType securityType = _elementParser.fromDartType(node.bestType, pc);
    for (var str in node.strings) {
      securityType = securityType.stampLabel(getSecurityType(str).label);
    }
    node.setProperty(SEC_TYPE_PROPERTY, securityType);
    return true;
  }

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    SecurityType securityType = _elementParser.fromDartType(node.bestType, pc);
    for (var elem in node.elements.where((e) => e is InterpolationExpression)) {
      securityType = securityType.stampLabel(getSecurityType(elem).label);
    }
    node.setProperty(SEC_TYPE_PROPERTY, securityType);
    return true;
  }

  @override
  bool visitInterpolationExpression(InterpolationExpression node) {
    node.visitChildren(this);
    node.setProperty(SEC_TYPE_PROPERTY, getSecurityType(node.expression));
    return true;
  }

  @override
  bool visitListLiteral(ListLiteral node) {
    node.visitChildren(this);

    var listSecType =
        new InterfaceSecurityTypeImpl.forExternalClass(pc, node.bestType);
    for (var elem in node.elements) {
      listSecType = listSecType.stampLabel(getSecurityType(elem).label);
    }
    node.setProperty(SEC_TYPE_PROPERTY, listSecType);
    return true;
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) {
    node.setProperty(SEC_TYPE_PROPERTY,
        new InterfaceSecurityTypeImpl.forExternalClass(pc, node.bestType));
    return true;
  }

  @override
  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.visitChildren(this);
    node.setProperty(
        SEC_TYPE_PROPERTY, node.identifier.getProperty(SEC_TYPE_PROPERTY));
    return true;
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    //TODO: Check if we should treat && and || in an special way
    node.leftOperand.accept(this);
    var leftSecType = getSecurityType(node.leftOperand);
    var leftSecLabel = leftSecType.label;

    node.rightOperand.accept(this);

    var rightSecType = getSecurityType(node.rightOperand);
    var rightSecLabel = rightSecType.label;

    final resultLabel = leftSecLabel.join(rightSecLabel);
    SecurityType resultType = new DynamicSecurityType(resultLabel);
    if (node.bestType is InterfaceType) {
      resultType = new InterfaceSecurityTypeImpl.forExternalClass(
          resultLabel, node.bestType);
    }
    node.setProperty(SEC_TYPE_PROPERTY, resultType);
    return true;
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    node.operand.accept(this);
    node.setProperty(
        SEC_TYPE_PROPERTY, node.operand.getProperty(SEC_TYPE_PROPERTY));
    return true;
  }

  @override
  bool visitPostfixExpression(PostfixExpression node) {
    node.operand.accept(this);
    node.setProperty(
        SEC_TYPE_PROPERTY, node.operand.getProperty(SEC_TYPE_PROPERTY));
    return true;
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    //TODO: refactor this method. Basically we do the same thing when
    //node.staticElement is a Parameter, LocalVariable or Property
    if (node.inGetterContext()) {
      if (node.staticElement is ParameterElement ||
          node.staticElement is LocalVariableElement ||
          node.staticElement is FunctionElement ||
          node.staticElement is PropertyAccessorElement) {
        //handle calls to Standard library
        if (node.staticElement is FunctionElement &&
            node.staticElement.library.name.contains("dart.core")) {
          //read annotation from dsl file
          node.setProperty(
              SEC_TYPE_PROPERTY,
              ExternalLibraryAnnotations.getSecTypeForFunction(
                  node.staticElement, _elementParser.lattice));
        } else {
          //resolved type by this visitor
          if (node.parent is FunctionDeclaration) {
            return false;
          }
          //TODO: Store the security type somewhere where the identifier is defined
          SecurityType securityType = null;
          if (node.staticElement is FunctionElement) {
            //take the security scheme from the function annotations
            securityType = _elementParser
                .securityTypeForFunctionElement(node.staticElement);
          } else if (node.staticElement is ParameterElement) {
            securityType = _elementParser.fromIdentifierDeclaration(
                node.staticElement, node.bestType);
          } else if (node.staticElement is LocalVariableElement) {
            securityType = _elementParser.fromIdentifierDeclaration(
                node.staticElement, node.bestType);
          } else if (node.staticElement is PropertyAccessorElement) {
            securityType =
                _elementParser.securityTypeForProperty(node.staticElement);
          }

          node.setProperty(SEC_TYPE_PROPERTY, securityType);
        }
      }
    } else if (node.inSetterContext()) {
      if (node.staticElement is ParameterElement ||
          node.staticElement is LocalVariableElement ||
          node.staticElement is PropertyAccessorElement) {
        SecurityType securityType = null;
        if (node.staticElement is LocalVariableElement) {
          securityType = _elementParser.fromIdentifierDeclaration(
              node.staticElement, node.bestType);
        } else if (node.staticElement is ParameterElement) {
          securityType = _elementParser.fromIdentifierDeclaration(
              node.staticElement, node.bestType);
        } else if (node.staticElement is PropertyAccessorElement) {
          securityType =
              _elementParser.securityTypeForProperty(node.staticElement);
        }
        node.setProperty(SEC_TYPE_PROPERTY, securityType);
      }
    }
    return true;
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    node.expression.accept(this);
    node.setProperty(SEC_TYPE_PROPERTY, getSecurityType(node.expression));
    return true;
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    //resolve argument security types
    node.argumentList.accept(this);
    //we only deal with "new C(...)"
    node.setProperty(
        SEC_TYPE_PROPERTY,
        new InterfaceSecurityTypeImpl(pc, node.bestType,
            _elementParser.securityInfoFromClass(node.bestType)));

    return true;
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    //visit left part
    node.leftHandSide.accept(this);
    //visit right side
    node.rightHandSide.accept(this);

    node.setProperty(
        SEC_TYPE_PROPERTY, node.leftHandSide.getProperty(SEC_TYPE_PROPERTY));
    return true;
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      node.expression.accept(this);
      node.setProperty(
          SEC_TYPE_PROPERTY, node.expression.getProperty(SEC_TYPE_PROPERTY));
    }
    return false;
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    for (VariableDeclaration variable in node.variables) {
      var initializer = variable.initializer;
      if (initializer != null) {
        //in the case the initializer  is constant, the label is the current
        // pc at that moment
        initializer.accept(this);
      }
    }
    node.visitChildren(this);
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    //visit the function expression
    node.function.accept(this);
    //get the function sec type
    var fSecType = getSecurityType(node.function);
    if (!(fSecType is SecurityFunctionType)) {
      reportError(SecurityTypeError.getCallNoFunction(node));
      return false;
    }

    node.argumentList.accept(this);

    SecurityFunctionType functionSecType = fSecType;
    node.setProperty(SEC_TYPE_PROPERTY,
        functionSecType.returnType.stampLabel(functionSecType.endLabel));
    return true;
  }

  //this apply to a.f() and f().
  @override
  bool visitMethodInvocation(MethodInvocation node) {
    //case: method invocation over object instance (eg.  a.f(1))
    SecurityFunctionType fSecType = null;
    SecurityType resultInvocationType = null;
    if (node.target != null) {
      node.target.accept(this);
      node.argumentList.accept(this);
      SecurityType receiverSType = getSecurityType(node.target);
      if (receiverSType is DynamicSecurityType) {
        //we return a dynamic label, but it could be the label of the receiver
        //too
        resultInvocationType =
            new DynamicSecurityType(_elementParser.lattice.dynamic);
      } else {
        //find the method in the class
        //include the security value of the target object
        fSecType = (receiverSType as InterfaceSecurityType)
            .getMethodSecurityType(node.methodName.staticElement.name);
        resultInvocationType = fSecType.returnType
            .stampLabel(fSecType.endLabel)
            .stampLabel(receiverSType.label);
      }
    } else {
      node.function.accept(this);
      node.argumentList.accept(this);
      //visit the function expression
      if (isDeclassifyOperator(node.function)) {
        resultInvocationType =
            _getSecTypeForInvocationToDeclassify(node.argumentList.arguments);
      } else {
        SecurityType receiverSType = getSecurityType(node.function);
        if (receiverSType is DynamicSecurityType) {
          resultInvocationType =
              new DynamicSecurityType(_elementParser.lattice.dynamic);
        } else {
          // get the function sec type.
          // TODO: We need to solve problem with library references
          fSecType = receiverSType;
          resultInvocationType =
              fSecType.returnType.stampLabel(fSecType.endLabel);
        }
      }
    }

    node.setProperty(SEC_TYPE_PROPERTY, resultInvocationType);
    return true;
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    //resolver security type for target
    node.target.accept(this);
    SecurityType receiverSType = getSecurityType(node.target);
    SecurityType resultInvocationType;
    if (receiverSType is DynamicSecurityType) {
      resultInvocationType =
          new DynamicSecurityType(_elementParser.lattice.dynamic);
    } else {
      //find the field in the class
      //include the security value of the target object
      var propertySecType = (receiverSType as InterfaceSecurityType)
          .getFieldSecurityType(node.propertyName.name);
      resultInvocationType = propertySecType.stampLabel(receiverSType.label);
    }
    node.setProperty(SEC_TYPE_PROPERTY, resultInvocationType);
    return true;
  }

  @override
  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    //PrefixedIdentifier has the form of c.f where c and f are both identifiers
    node.prefix.accept(this);

    SecurityType receiverSType = getSecurityType(node.prefix);
    SecurityType resultInvocationType;
    if (receiverSType is DynamicSecurityType) {
      resultInvocationType =
          new DynamicSecurityType(_elementParser.lattice.dynamic);
    } else {
      //find the field in the class
      //include the security value of the target object
      var propertySecType = (receiverSType as InterfaceSecurityType)
          .getFieldSecurityType(node.identifier.name);
      resultInvocationType = propertySecType.stampLabel(receiverSType.label);
    }
    node.setProperty(SEC_TYPE_PROPERTY, resultInvocationType);
    return true;
  }

  SecurityType _getSecTypeForInvocationToDeclassify(
      NodeList<Expression> argumentList) {
    assert(argumentList.length == 2);
    final actualArgumentToDeclassify = argumentList[0];
    final secType = getSecurityType(actualArgumentToDeclassify);
    final stringLabel = argumentList[1];
    final label = stringLabel.getProperty(SEC_LABEL_PROPERTY);
    return secType.downgradeLabel(label);
  }
}
