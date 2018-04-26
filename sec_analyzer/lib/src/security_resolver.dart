import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/annotations/parser_element.dart';
import 'package:secdart_analyzer/src/gs_typesystem.dart';
import 'package:secdart_analyzer/src/helper.dart';
import 'package:secdart_analyzer/src/security_visitor.dart';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

import 'security_type.dart';

/**
 * This resolver assumes:
 * - The security parser was already execute over the AST
 * - The [LabelMap] was filled with the label information
 * - The node that carry security annotations have the [SEC_LABEL_PROPERTY]
 * correctly set.
 */
class TopLevelDeclarationResolver extends RecursiveAstVisitor<bool> {
  SecurityElementResolver _secElementResolver;

  TopLevelDeclarationResolver(SecurityElementResolver resolver) {
    _secElementResolver = resolver;
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    //obtain the security type from annotations. It will be use
    //the label cache internally.
    final securityElement =
        _secElementResolver.getSecurityFunction(node.element);
    node.setProperty(SEC_TYPE_PROPERTY, securityElement.functionType);
    node.setProperty(SECURITY_ELEMENT, securityElement);

    node.visitChildren(this);
    return true;
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    //we assume that that labels were already parsed
    SecurityElement securityElement;
    if (!(node.isGetter || node.isSetter)) {
      final securityMethodElement =
          _secElementResolver.getSecurityMethod(node.element);
      node.setProperty(SEC_TYPE_PROPERTY, securityMethodElement.methodType);
      securityElement = securityMethodElement;
    } else {
      final securityPropertyElement =
          _secElementResolver.getSecurityPropertyAccessor(node.element);
      node.setProperty(SEC_TYPE_PROPERTY, securityPropertyElement.propertyType);
      securityElement = securityPropertyElement;
    }
    node.setProperty(SECURITY_ELEMENT, securityElement);

    //we need to visit nested function declarations
    node.visitChildren(this);
    return true;
  }

  @override
  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    var securityElement =
        _secElementResolver.getSecurityConstructor(node.element);

    node.setProperty(SEC_TYPE_PROPERTY, securityElement.constructorType);
    node.setProperty(SECURITY_ELEMENT, securityElement);

    //we need to visit nested function declarations
    node.visitChildren(this);
    return true;
  }
}

class SecurityIdentifierResolver {
  SecurityElementResolver _elementResolver;

  SecurityIdentifierResolver(SecurityElementResolver elementResolver) {
    _elementResolver = elementResolver;
  }

  bool resolveIdentifier(SimpleIdentifier node) {
    //TODO: refactor this method. Basically we do the same thing when
    //node.staticElement is a Parameter, LocalVariable or Property
    if (node.inGetterContext()) {
      if (node.staticElement is ParameterElement ||
          node.staticElement is LocalVariableElement ||
          node.staticElement is FunctionElement ||
          node.staticElement is PropertyAccessorElement ||
          node.staticElement is MethodElement) {
        //resolved type by this visitor
        if (node.parent is FunctionDeclaration) {
          return false;
        }
        SecurityType securityType = null;
        if (node.staticElement is FunctionElement) {
          securityType = _elementResolver
              .getSecurityFunction(node.staticElement)
              .functionType;
        } else if (node.staticElement is MethodElement) {
          securityType =
              _elementResolver.getSecurityMethod(node.staticElement).methodType;
        } else if (node.staticElement is ParameterElement) {
          securityType = _elementResolver.fromIdentifierDeclaration(
              node.staticElement, node.bestType);
        } else if (node.staticElement is LocalVariableElement) {
          securityType = _elementResolver.fromIdentifierDeclaration(
              node.staticElement, node.bestType);
        } else if (node.staticElement is PropertyAccessorElement) {
          //check if the property is accessed through an instance or not.
          final propertyType = _elementResolver
              .getSecurityPropertyAccessor(node.staticElement)
              .propertyType as SecurityFunctionType;
          if (node.parent is PropertyAccess) {
            securityType = propertyType;
          } else {
            securityType = propertyType.returnType;
          }
        }

        node.setProperty(SEC_TYPE_PROPERTY, securityType);
      }
    } else if (node.inSetterContext()) {
      if (node.staticElement is ParameterElement ||
          node.staticElement is LocalVariableElement ||
          node.staticElement is PropertyAccessorElement) {
        SecurityType securityType = null;
        if (node.staticElement is LocalVariableElement) {
          securityType = _elementResolver.fromIdentifierDeclaration(
              node.staticElement, node.bestType);
        } else if (node.staticElement is ParameterElement) {
          securityType = _elementResolver.fromIdentifierDeclaration(
              node.staticElement, node.bestType);
        } else if (node.staticElement is PropertyAccessorElement) {
          securityType = _elementResolver
              .getSecurityPropertyAccessor(node.staticElement)
              .propertyType;
        }
        node.setProperty(SEC_TYPE_PROPERTY, securityType);
      }
    }
    return true;
  }
}

/**
 * This visitor resolves the security types for every supported expression
 *
 * It basically computes labels for expressions.
 */
class SecurityResolverVisitor extends AbstractSecurityVisitor {
  SecurityElementResolver _elementResolver;
  GradualLattice _lattice;
  SecurityIdentifierResolver _identifierResolver;
  GradualSecurityTypeSystem typeSystem;

  SecurityResolverVisitor(AnalysisErrorListener reporter,
      SecurityElementResolver elementResolver, SecurityCache securityMap)
      : super(reporter, securityMap) {
    _elementResolver = elementResolver;
    _lattice = _elementResolver.lattice;
    typeSystem = new GradualSecurityTypeSystem();
    pc = _elementResolver.lattice.dynamic;
    _identifierResolver = new SecurityIdentifierResolver(elementResolver);
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
        .join(secTypeThenExpr, secTypeElseExpr, node.bestType, _elementResolver)
        .stampLabel(conditionalSecType.label);

    node.setProperty(SEC_TYPE_PROPERTY, resultType);
    pc = currentPc;

    return true;
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    List<SecurityType> parameterSecTypes = [];
    for (FormalParameter parameter in node.parameters.parameters) {
      parameterSecTypes.add(_elementResolver.fromIdentifierDeclaration(
          parameter.element, parameter.element.type));
    }
    var securityType = new SecurityFunctionTypeImpl(
        _lattice.dynamic,
        parameterSecTypes,
        _elementResolver
            .fromDartType(node.element.returnType)
            .toSecurityType(pc),
        _lattice.dynamic);

    node.setProperty(SEC_TYPE_PROPERTY, securityType);
    super.visitFunctionExpression(node);
    return true;
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    node.setProperty(SEC_TYPE_PROPERTY,
        _elementResolver.fromDartType(node.bestType).toSecurityType(pc));
    return true;
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    node.setProperty(SEC_TYPE_PROPERTY,
        _elementResolver.fromDartType(node.bestType).toSecurityType(pc));
    return true;
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    //this method is call for any string literal including import uris,
    //and annotations arguments which are not relevant for the security analysis.
    //By checking the pc!=null we avoid to process those nodes.
    if (pc != null) {
      node.setProperty(SEC_TYPE_PROPERTY,
          _elementResolver.fromDartType(node.bestType).toSecurityType(pc));
    }
    return true;
  }

  @override
  bool visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
    SecurityType securityType =
        _elementResolver.fromDartType(node.bestType).toSecurityType(pc);
    for (var str in node.strings) {
      securityType = securityType.stampLabel(getSecurityType(str).label);
    }
    node.setProperty(SEC_TYPE_PROPERTY, securityType);
    return true;
  }

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    SecurityType securityType =
        _elementResolver.fromDartType(node.bestType).toSecurityType(pc);
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
        _elementResolver.fromDartType(node.bestType).toSecurityType(pc);
    for (var elem in node.elements) {
      listSecType = listSecType.stampLabel(getSecurityType(elem).label);
    }
    node.setProperty(SEC_TYPE_PROPERTY, listSecType);
    return true;
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) {
    node.setProperty(SEC_TYPE_PROPERTY,
        _elementResolver.fromDartType(node.bestType).toSecurityType(pc));
    return true;
  }

  @override
  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.visitChildren(this);
    node.setProperty(SEC_TYPE_PROPERTY, getSecurityType(node.identifier));
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
    SecurityType resultType = _elementResolver
        .fromDartType(node.bestType)
        .toSecurityType(resultLabel);

    node.setProperty(SEC_TYPE_PROPERTY, resultType);
    return true;
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    node.operand.accept(this);
    node.setProperty(SEC_TYPE_PROPERTY, getSecurityType(node.operand));
    return true;
  }

  @override
  bool visitPostfixExpression(PostfixExpression node) {
    node.operand.accept(this);
    node.setProperty(SEC_TYPE_PROPERTY, getSecurityType(node.operand));
    return true;
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    return _identifierResolver.resolveIdentifier(node);
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    node.expression.accept(this);
    node.setProperty(SEC_TYPE_PROPERTY, getSecurityType(node.expression));
    return true;
  }

  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    final securityClassElement =
        _elementResolver.getSecurityClass(node.element);

    node.setProperty(SECURITY_ELEMENT, securityClassElement);

    node.visitChildren(this);
    return true;
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    //resolve argument security types
    node.argumentList.accept(this);
    //we only deal with "new C(...)"
    node.setProperty(
        SEC_TYPE_PROPERTY,
        new InterfaceSecurityTypeImpl(
            pc,
            new PreInterfaceTypeImpl(
                _elementResolver.getSecurityClass(node.bestType.element))));

    return true;
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    //visit left part
    node.leftHandSide.accept(this);
    //visit right side
    node.rightHandSide.accept(this);

    node.setProperty(SEC_TYPE_PROPERTY, getSecurityType(node.leftHandSide));
    return true;
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      node.expression.accept(this);
      node.setProperty(SEC_TYPE_PROPERTY, getSecurityType(node.expression));
    }
    return false;
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    //the parser left the annotated label in node, so we can build the security
    //type
    SimpleAnnotatedLabel simpleAnnotatedLabel =
        node.getProperty(SEC_LABEL_PROPERTY);
    SecurityLabel label =
        _elementResolver.labelNodeToLabelElement(simpleAnnotatedLabel.label);

    for (VariableDeclaration variable in node.variables) {
      //get the type for the variable. We cannot get the type from node.type
      //because when there is no type annotation it returns null. So we rely
      //here on the Dart type inference and get the type from the variable.
      SecurityType securityType = _elementResolver
          .fromDartType(variable.element.type)
          .toSecurityType(label);
      variable.setProperty(SEC_TYPE_PROPERTY, securityType);

      variable.visitChildren(this);
    }
    return true;
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    //visit the function expression
    node.function.accept(this);
    //get the function sec type
    var fSecType = getSecurityType(node.function);

    node.argumentList.accept(this);

    SecurityType resultInvocationType = null;
    if (fSecType is DynamicSecurityType) {
      resultInvocationType = new DynamicSecurityTypeImpl(_lattice.dynamic);
    } else if (fSecType is InterfaceSecurityType &&
        isFunctionInstance(node.function)) {
      fSecType = new DynamicSecurityTypeImpl(_lattice.dynamic);
    } else if (fSecType is SecurityFunctionType) {
      resultInvocationType = fSecType.returnType.stampLabel(fSecType.endLabel);
    }

    node.setProperty(SEC_TYPE_PROPERTY, resultInvocationType);
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
        resultInvocationType = new DynamicSecurityTypeImpl(_lattice.dynamic);
      } else {
        //find the method in the class
        //include the security value of the target object
        fSecType = (receiverSType as InterfaceSecurityType)
            .getMethodSecurityType(node.methodName.staticElement.name);
        resultInvocationType = fSecType.returnType
            .stampLabel(fSecType.endLabel)
            .stampLabel(receiverSType.label);
      }
    }
    //case: f(arg ...)
    else {
      node.function.accept(this);
      node.argumentList.accept(this);
      //visit the function expression
      if (isDeclassifyOperator(node.function)) {
        resultInvocationType =
            _getSecTypeForInvocationToDeclassify(node.argumentList.arguments);
      } else {
        SecurityType receiverSType = getSecurityType(node.function);
        if (receiverSType is DynamicSecurityType) {
          resultInvocationType = new DynamicSecurityTypeImpl(_lattice.dynamic);
        } else if (receiverSType is InterfaceSecurityType &&
            isFunctionInstance(node.function)) {
          //TODO: check if where are invocation to Function instance
          resultInvocationType = new DynamicSecurityTypeImpl(_lattice.dynamic);
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
  bool visitThisExpression(ThisExpression node) {
    //TODO: fix this
    node.setProperty(
        SEC_TYPE_PROPERTY,
        _elementResolver
            .fromDartType(node.bestType)
            .toSecurityType(_lattice.dynamic));
    return true;
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    //resolver security type for target
    node.target.accept(this);
    SecurityType receiverSType = getSecurityType(node.target);
    SecurityType resultInvocationType;
    if (receiverSType is DynamicSecurityType) {
      resultInvocationType = new DynamicSecurityTypeImpl(_lattice.dynamic);
    } else {
      //find the field in the class
      //include the security value of the target object
      if (receiverSType is InterfaceSecurityType) {
        var propertySecType =
            receiverSType.getGetterSecurityType(node.propertyName.name);
        if (propertySecType is SecurityFunctionType) {
          resultInvocationType =
              propertySecType.returnType.stampLabel(receiverSType.label);
        }
      } else {
        //TODO: check this
        resultInvocationType = receiverSType.stampLabel(receiverSType.label);
      }
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
      resultInvocationType = new DynamicSecurityTypeImpl(_lattice.dynamic);
    } else if (receiverSType is InterfaceSecurityType) {
      //find the field in the class
      //include the security value of the target object
      var propertySecType =
          receiverSType.getGetterSecurityType(node.identifier.name);
      if (propertySecType is SecurityFunctionType) {
        resultInvocationType =
            propertySecType.returnType.stampLabel(receiverSType.label);
      } else {
        resultInvocationType = receiverSType.stampLabel(receiverSType.label);
      }
    }
    node.setProperty(SEC_TYPE_PROPERTY, resultInvocationType);
    return true;
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    String getterMethodName = TokenType.INDEX.lexeme;
    String setterMethodName = TokenType.INDEX_EQ.lexeme;
    //l[1], capitals["Spain"]
    //resolver security type for target
    node.target.accept(this);
    node.index.accept(this);

    SecurityType receiverSType = getSecurityType(node.target);
    SecurityType resultInvocationType;
    if (receiverSType is DynamicSecurityType) {
      resultInvocationType = new DynamicSecurityTypeImpl(_lattice.dynamic);
    } else if (node.inGetterContext()) {
      //find the field in the class
      //include the security value of the target object
      var getterSecurityType = (receiverSType as InterfaceSecurityType)
          .getMethodSecurityType(getterMethodName);

      if (getterSecurityType is SecurityFunctionType) {
        resultInvocationType =
            getterSecurityType.returnType.stampLabel(receiverSType.label);
      } else {
        resultInvocationType =
            getterSecurityType.stampLabel(receiverSType.label);
      }
    } else if (node.inSetterContext()) {
      var setterSecurityType = (receiverSType as InterfaceSecurityType)
          .getMethodSecurityType(setterMethodName);
      if (setterSecurityType is SecurityFunctionType) {
        resultInvocationType =
            setterSecurityType.returnType.stampLabel(receiverSType.label);
      } else {
        resultInvocationType =
            setterSecurityType.stampLabel(receiverSType.label);
      }
    }
    node.setProperty(SEC_TYPE_PROPERTY, resultInvocationType);
    return true;
  }

  @override
  bool visitAnnotation(Annotation node) {
    ///we do not visit node children because we can not apply the security
    ///resolver over annotations.
    return true;
  }

  SecurityType _getSecTypeForInvocationToDeclassify(
      NodeList<Expression> argumentList) {
    assert(argumentList.length == 2);
    final actualArgumentToDeclassify = argumentList[0];
    final secType = getSecurityType(actualArgumentToDeclassify);
    final stringLabel = argumentList[1];
    final label = stringLabel.getProperty(SEC_LABEL_PROPERTY);
    return secType
        .downgradeLabel(_elementResolver.labelNodeToLabelElement(label));
  }
}
