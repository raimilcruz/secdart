import 'package:analyzer/error/listener.dart';
import 'package:secdart_analyzer/src/annotations/parser_element.dart';
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
  ElementAnnotationParserHelper _elementParser;

  SecurityResolverVisitor(AnalysisErrorListener reporter,
      [bool intervalMode = false])
      : super(reporter, intervalMode) {
    _elementParser = new ElementAnnotationParserHelper(intervalMode);
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    //visit the if node
    node.condition.accept(this);
    var secType = getSecurityType(node.condition);
    //increase the pc
    var currentPc = pc;
    pc = pc.join(secType.label);

    //visit both branches
    node.thenExpression.accept(this);

    node.elseExpression.accept(this);

    final secTypeThenExpr = getSecurityType(node.thenExpression);
    final secTypeElseExpr = getSecurityType(node.elseExpression);

    SecurityType resultType = null;
    if (secTypeThenExpr is InterfaceSecurityType &&
        secTypeElseExpr is InterfaceSecurityType) {
      final resultLabel =
          secTypeThenExpr.label.join(secTypeElseExpr.label).join(secType.label);
      resultType = new InterfaceSecurityTypeImpl(resultLabel,
          _elementParser.securityInfoFromClass(node.bestType.element));
    } else {
      resultType =
          secTypeElseExpr.join(secTypeThenExpr).stampLabel(secType.label);
    }
    node.setProperty(SEC_TYPE_PROPERTY, resultType);
    pc = currentPc;

    return true;
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    node.setProperty(SEC_TYPE_PROPERTY, new GroundSecurityType(pc));
    return true;
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    node.setProperty(SEC_TYPE_PROPERTY, new GroundSecurityType(pc));
    return true;
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    node.setProperty(SEC_TYPE_PROPERTY, new GroundSecurityType(pc));
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

    var resultType = new GroundSecurityType(leftSecLabel.join(rightSecLabel));
    node.setProperty(SEC_TYPE_PROPERTY, resultType);
    return true;
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inGetterContext()) {
      if (node.staticElement is ParameterElement ||
          node.staticElement is LocalVariableElement ||
          node.staticElement is FunctionElement) {
        //handle calls to Standard library
        if (node.staticElement is FunctionElement &&
            node.staticElement.library.name.contains("dart.core")) {
          //read annotation from dsl file
          node.setProperty(
              SEC_TYPE_PROPERTY,
              ExternalLibraryAnnotations.getSecTypeForFunction(
                  node.name, _elementParser.dynamicLabel));
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
            securityType =
                _elementParser.getSecurityTypeForParameter(node.staticElement);
          } else if (node.staticElement is LocalVariableElement) {
            securityType =
                _elementParser.securityTypeForLocalVariable(node.staticElement);
          }

          node.setProperty(SEC_TYPE_PROPERTY, securityType);
        }
      }
    } else if (node.inSetterContext()) {
      if (node.staticElement is LocalVariableElement) {
        var referredNode = node.staticElement.computeNode();
        node.setProperty(
            SEC_TYPE_PROPERTY, referredNode.getProperty(SEC_TYPE_PROPERTY));
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
    //we only deal with "new C(...)"
    if (node.bestType.element is ClassElement) {
      node.setProperty(
          SEC_TYPE_PROPERTY,
          new InterfaceSecurityTypeImpl(
              pc, _elementParser.securityInfoFromClass(node.bestType.element)));
    } else if (!node.isConst) {
      node.setProperty(SEC_TYPE_PROPERTY, new GroundSecurityType(pc));
    }
    return true;
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    //visit left part
    node.leftHandSide.accept(this);
    //visit right side
    node.rightHandSide.accept(this);
    return true;
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      node.expression.accept(this);
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
      SecurityType receiverSType = getSecurityType(node.target);
      if (receiverSType is DynamicSecurityType) {
        resultInvocationType =
            new DynamicSecurityType(_elementParser.dynamicLabel);
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
      //visit the function expression
      node.function.accept(this);
      SecurityType receiverSType = getSecurityType(node.function);
      if (receiverSType is DynamicSecurityType) {
        resultInvocationType =
            new DynamicSecurityType(_elementParser.dynamicLabel);
      } else {
        // get the function sec type.
        // TODO: We need to solve problem with library references
        fSecType = receiverSType;
        resultInvocationType =
            fSecType.returnType.stampLabel(fSecType.endLabel);
      }
    }
    node.argumentList.accept(this);

    node.setProperty(SEC_TYPE_PROPERTY, resultInvocationType);
    return true;
  }
}
