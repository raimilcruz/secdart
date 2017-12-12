import 'package:analyzer/error/listener.dart';

import 'errors.dart';
import 'gs_typesystem.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/dart/element/element.dart';

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'security_type.dart';
import 'security_label.dart';

final String SEC_TYPE_PROPERTY = "sec-type";

/**
 * This visitor performs an information-flow analysis over a resolved AST.
 *
 * Assumption:
 * - The AST is already resolved
 * - The security annotations are already parsed
 * - The AST represents a program of the supported subset
 *
 * This implementation has taken a lot of code from CodeChecker
 * (analyzer\src\task\strong\checker.dart)
 */
class SecurityVisitor extends RecursiveAstVisitor<bool> {
  //The implementation of the security type system
  final GradualSecurityTypeSystem secTypeSystem;
  final AnalysisErrorListener reporter;
  final bool intervalMode;

  /**
   * The program counter label
   */
  SecurityLabel _pc = null;

  /**
   * The element representing the function containing the current node,
   * or `null` if the current node is not contained in a function.
   */
  ExecutableElement _enclosingFunction;
  FunctionDeclaration _enclosingFunctionDeclaration;

  SecurityVisitor(this.secTypeSystem, this.reporter,
      [bool this.intervalMode = false]) {}

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    try {
      node.visitChildren(this);
    } on SecDartException catch (e) {
      reportError(SecurityTypeError.toAnalysisError(node,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.getMessage()]));
    } on Exception catch (e) {
      reportError(SecurityTypeError.toAnalysisError(node,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.toString()]));
    } catch (e) {
      reportError(SecurityTypeError.toAnalysisError(node,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.toString()]));
    }
    return null;
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    //we assume that that label were already parsed
    //TODO: Deal with dynamic types (for functions)
    var secType = node.getProperty(SEC_TYPE_PROPERTY) as SecurityFunctionType;
    _checkFunctionSecType(node,secType);

    var currentPc = _pc;
    ExecutableElement outerFunction = _enclosingFunction;
    _enclosingFunction = node.element;

    FunctionDeclaration outerFunctionDecl = _enclosingFunctionDeclaration;
    _enclosingFunctionDeclaration = node;

    //TODO: update pc or join?
    _pc = secType.beginLabel;

    var result = super.visitFunctionDeclaration(node);

    _enclosingFunction = outerFunction;
    _enclosingFunctionDeclaration = outerFunctionDecl;
    _pc = currentPc;
    return result;
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    //visit the function expression
    node.function.accept(this);
    //get the function sec type
    var fSecType = _getSecurityType(node.function);
    if (!(fSecType is SecurityFunctionType)) {
      reportError(SecurityTypeError.getCallNoFunction(node));
      return false;
    }
    SecurityFunctionType functionSecType = fSecType;
    var beginLabel = functionSecType.beginLabel;
    var endLabel = functionSecType.endLabel;
    //check the pc is enough high to invoke the function
    if (beginLabel.canRelabeledTo(_pc.join(endLabel))) {
      reportError(SecurityTypeError.getBadFunctionCall(node));
      return false;
    }

    node.argumentList.accept(this);

    //foreach function formal argument type, ensure each actual argument
    // type is a subtype
    checkArgumentList(node.argumentList, functionSecType);

    node.setProperty(SEC_TYPE_PROPERTY,
        functionSecType.returnType.stampLabel(functionSecType.endLabel));

    return true;
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    //visit the function expression
    node.function.accept(this);
    // get the function sec type.
    // This does not work when the function is another file.
    // TODO: We need to solve problem with library references
    var fSecType = _getSecurityType(node.function);
    if (!(fSecType is SecurityFunctionType)) {
      reportError(SecurityTypeError.getCallNoFunction(node));
      return false;
    }
    SecurityFunctionType functionSecType = fSecType;
    var beginLabel = functionSecType.beginLabel;
    var endLabel = functionSecType.endLabel;
    //check the pc is enough high to invoke the function
    if (!(_pc.join(endLabel).lessOrEqThan(beginLabel))) {
      reportError(SecurityTypeError.getBadFunctionCall(node));
      return false;
    }

    node.argumentList.accept(this);

    //foreach function formal argument type, ensure each actual argument
    //type is a subtype
    checkArgumentList(node.argumentList, functionSecType);

    node.setProperty(SEC_TYPE_PROPERTY,
        functionSecType.returnType.stampLabel(functionSecType.endLabel));
    return true;
  }

  void checkArgumentList(
      ArgumentList node, SecurityFunctionType functionSecType) {
    NodeList<Expression> list = node.arguments;
    int len = list.length;
    for (int i = 0; i < len; ++i) {
      Expression expr = list[i];

      var secTypeFormalArg = functionSecType.argumentTypes[i];
      checkSubtype(expr, _getSecurityType(expr), secTypeFormalArg);
    }
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    for (VariableDeclaration variable in node.variables) {
      var initializer = variable.initializer;
      if (initializer != null) {
        //TODO: TO have a method more specific for that
        var secType = _getSecurityType(variable);
        //in the case the initializer  is constant, the label is the current
        // pc at that moment
        initializer.accept(this);
        var initializerSecType = _getSecurityType(initializer);
        initializer.setProperty(SEC_TYPE_PROPERTY, initializerSecType);
        checkAssignment(initializer, secType, variable);
      }
    }
    node.visitChildren(this);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    //visit left part
    node.leftHandSide.accept(this);
    //visit right side
    node.rightHandSide.accept(this);
    //get both security types
    var leftSecType = _getSecurityType(node.leftHandSide);
    var rigthSecType = _getSecurityType(node.rightHandSide);

    _checkAssignment2(node.leftHandSide, leftSecType, rigthSecType, node);
    return true;
  }

  @override
  bool visitIfStatement(IfStatement node) {
    //visit the if node
    node.condition.accept(this);
    var secType = _getSecurityType(node.condition);
    //increase the pc
    var currentPc = _pc;
    _pc = _pc.join(secType.label);

    //visit both branches
    node.thenStatement.accept(this);

    if (node.elseStatement != null) {
      node.elseStatement.accept(this);
    }
    _pc = currentPc;
    return true;
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    //TODO: Check if we should treat && and || in an special way
    node.leftOperand.accept(this);
    var leftSecType = _getSecurityType(node.leftOperand);
    var leftSecLabel = _getLabel(leftSecType);

    node.rightOperand.accept(this);

    var rightSecType = _getSecurityType(node.rightOperand);
    var rightSecLabel = _getLabel(rightSecType);

    var resultType = new GroundSecurityType(
        node.staticType, leftSecLabel.join(rightSecLabel));
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
          node.setProperty(SEC_TYPE_PROPERTY,
              ExternalLibraryAnnotations.getSecTypeForFunction(node.name));
        } else {
          //resolved type by this visitor
          var referedNode = node.staticElement.computeNode();
          node.setProperty(
              SEC_TYPE_PROPERTY, referedNode.getProperty(SEC_TYPE_PROPERTY));
        }
      }
    } else if (node.inSetterContext()) {
      if (node.staticElement is LocalVariableElement) {
        var referedNode = node.staticElement.computeNode();
        node.setProperty(
            SEC_TYPE_PROPERTY, referedNode.getProperty(SEC_TYPE_PROPERTY));
      }
    }
    return true;
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      node.expression.accept(this);
      var secType = _getSecurityType(node.expression);

      var functionSecType =
      _enclosingFunctionDeclaration.getProperty(SEC_TYPE_PROPERTY) as
      SecurityFunctionType;
      if (secTypeSystem.isSubtypeOf(secType, functionSecType.returnType)) {
        return true;
      }

      reportError(SecurityTypeError.getReturnTypeError(
          node, functionSecType.returnType, secType));
    }
    return false;
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    //visit the if node
    node.condition.accept(this);
    var secType = _getSecurityType(node.condition);
    //increase the pc
    var currentPc = _pc;
    _pc = _pc.join(_getLabel(secType));

    //visit both branches
    node.thenExpression.accept(this);

    node.elseExpression.accept(this);

    var secTypeThenExpr = _getSecurityType(node.thenExpression);
    var secTypeElseExpr = _getSecurityType(node.elseExpression);

    //TODO: This is wrong for high order types
    var resultType = new GroundSecurityType(node.staticType,
        secTypeThenExpr.label.join(secTypeElseExpr.label).join(secType.label));
    node.setProperty(SEC_TYPE_PROPERTY, resultType);
    _pc = currentPc;

    return true;
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    node.setProperty(
        SEC_TYPE_PROPERTY, new GroundSecurityType(node.staticType, _pc));
    return true;
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    node.setProperty(
        SEC_TYPE_PROPERTY, new GroundSecurityType(node.staticType, _pc));
    return true;
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    node.setProperty(
        SEC_TYPE_PROPERTY, new GroundSecurityType(node.staticType, _pc));
    return true;
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    node.expression.accept(this);
    node.setProperty(SEC_TYPE_PROPERTY, _getSecurityType(node.expression));
    return true;
  }

  /**
   * Checks that an expression can be assigned to a type
   */
  void checkAssignment(
      Expression expr, SecurityType type, VariableDeclaration node) {
    if (expr is ParenthesizedExpression) {
      checkAssignment(expr.expression, type, node);
    } else {
      _checkAssignment(expr, type, node);
    }
  }

  void _checkAssignment(
      Expression expr, SecurityType to, VariableDeclaration node,
      {SecurityType from}) {
    if (from == null) {
      from = _getSecurityType(expr);
    }
    // fromT <: toT, no coercion needed.
    if (secTypeSystem.isSubtypeOf(from, to)) {
      var labelTo = _getLabel(to);
      //var labelFrom = _getLabel(from);
      if (_pc.canRelabeledTo(labelTo)) return;
    }
    reportError(SecurityTypeError.getExplicitFlowError(node, from, to));
  }

  void _checkAssignment2(Expression expr, SecurityType to, SecurityType from,
      AssignmentExpression node) {
    if (secTypeSystem.isSubtypeOf(from, to)) {
      var labelTo = _getLabel(to);
      //var labelFrom = _getLabel(from);
      if (_pc.canRelabeledTo(labelTo)) return;
    }
    //TODO: Report error
    reportError(SecurityTypeError.getExplicitFlowError(node, from, to));
  }

  void checkSubtype(Expression expr, SecurityType from, SecurityType to) {
    if (secTypeSystem.isSubtypeOf(from, to)) {
      var labelTo = _getLabel(to);
      //var labelFrom = _getLabel(from);
      if (_pc.canRelabeledTo(labelTo)) return;
    }

    //TODO: Report error
    reportError(SecurityTypeError.getExplicitFlowError(expr, from, to));
  }

  /**
   * Get the label from a security type.
   */
  SecurityLabel _getLabel(SecurityType secType) {
    return secType.label;
  }

  /**
   * Report an [AnalysisError] to the underline [AnalysisErrorListener]
   */
  void reportError(AnalysisError explicitFlowError) {
    reporter.onError(explicitFlowError);
  }

  /**
   * Get the security type associated to an expression. The security type need to be resolved for the expression
   */
  SecurityType _getSecurityType(AstNode expr) {
    var result = expr.getProperty(SEC_TYPE_PROPERTY);
    if (result == null) {
      reportError(SecurityTypeError.toAnalysisError(
          expr,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR,
          new List<Object>()
            ..add("Expression does not "
                "have a security type (For instance it happens when a calling a function in another library, we do not how to deal"
                "with multiple file yet)")));
      throw new UnsupportedFeatureException(
          "Error in SecurityVisitor._getSecurityType");
    }
    return result;
  }

  DartType getDartType(TypeName name) {
    return (name == null) ? DynamicTypeImpl.instance : name.type;
  }

  void _checkFunctionSecType(
      FunctionDeclaration decl, SecurityFunctionType secType) {
    //TODO: Be careful. In the next implementation iteration we will deal with first class functions
  }
}

class ExternalLibraryAnnotations {
  static SecurityType getSecTypeForFunction(String name) {
    if (name == "print")
      return new SecurityFunctionType(
          new LowLabel(),
          [new GroundSecurityType(DynamicTypeImpl.instance, new LowLabel())],
          new GroundSecurityType(VoidTypeImpl.instance, new LowLabel()),
          new LowLabel());
    return new SecurityFunctionType(
        new DynamicLabel(),
        new List<SecurityType>(),
        new GroundSecurityType(VoidTypeImpl.instance, new DynamicLabel()),
        new DynamicLabel());
  }
}
