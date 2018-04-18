import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';

import 'errors.dart';
import 'gs_typesystem.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'security_type.dart';

/**
 * Abstract visitor to track the program counter and
 * factorize common operations for [SecurityResolverVisitor]
 * and [SecurityCheckerVisitor]
 */
class AbstractSecurityVisitor extends RecursiveAstVisitor<bool> {
  /**
   * The program counter label
   */
  SecurityLabel pc = null;
  LibraryElement _library;
  SecurityCache securityMap;

  /**
   * The element representing the function containing the current node,
   * or `null` if the current node is not contained in a function.
   */
  SecurityFunctionType _enclosingExecutableElementSecurityType;

  final AnalysisErrorListener reporter;

  AbstractSecurityVisitor(this.reporter, this.securityMap);

  /**
   * Get the security type associated to an expression. The security type need to be resolved for the expression
   */
  SecurityType getSecurityType(AstNode expr) {
    var stackTrace = StackTrace.current.toString();
    if (expr == null) {
      throw new ArgumentError("getSecurityType method was invoked with null. "
          "Stack trace: $stackTrace");
    }
    var result = expr.getProperty(SEC_TYPE_PROPERTY);
    if (result == null) {
      reportError(SecurityTypeError.toAnalysisError(
          expr,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR,
          new List<Object>()
            ..add("Expression $expr does not "
                "have a security type. This happens with expressions that "
                "the security analysis does not support")));
      throw new UnsupportedFeatureException(expr,
          "Error in SecurityVisitor._getSecurityType. Stack trace: $stackTrace");
    }
    return result;
  }

  /**
   * Report an [AnalysisError] to the underline [AnalysisErrorListener]
   */
  void reportError(AnalysisError explicitFlowError) {
    reporter.onError(explicitFlowError);
  }

  DartType getDartType(TypeName name) {
    return (name == null) ? DynamicTypeImpl.instance : name.type;
  }

  bool isFunctionInstance(Expression function) {
    return (function.bestType is InterfaceType &&
        function.bestType.name == "Function");
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    //TODO: receive as parameter
    _library = node.element.library;
    try {
      node.visitChildren(this);
    } on UnsupportedFeatureException catch (e) {
      reportError(SecurityTypeError.toAnalysisError(e.node,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.getMessage()]));
    } on SecDartException catch (e) {
      reportError(SecurityTypeError.toAnalysisError(node,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.getMessage()]));
    } on Exception catch (e) {
      reportError(SecurityTypeError.toAnalysisError(node,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.toString()]));
    } on Error catch (e) {
      reportError(SecurityTypeError.toAnalysisError(
          node,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR,
          [e.toString() + "Stack trace: ${e.stackTrace.toString()}"]));
    }
    return true;
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    //we assume that that labels were already parsed
    var annotatedLabels =
        node.getProperty(SEC_LABEL_PROPERTY) as FunctionLevelLabels;

    var currentPc = pc;
    var outerFunctionType = _enclosingExecutableElementSecurityType;
    _enclosingExecutableElementSecurityType = getSecurityType(node);

    pc = pc.join(annotatedLabels.functionLabels.beginLabel);

    super.visitFunctionDeclaration(node);

    _enclosingExecutableElementSecurityType = outerFunctionType;
    pc = currentPc;
    return true;
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    //we assume that that labels were already parsed
    var annotatedLabels =
        node.getProperty(SEC_LABEL_PROPERTY) as FunctionLevelLabels;

    var currentPc = pc;
    var outerFunctionType = _enclosingExecutableElementSecurityType;
    _enclosingExecutableElementSecurityType = getSecurityType(node);

    //TODO: update pc or join?
    pc = annotatedLabels.functionLabels.beginLabel;

    var result = super.visitMethodDeclaration(node);

    _enclosingExecutableElementSecurityType = outerFunctionType;
    pc = currentPc;
    return result;
  }

  @override
  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    var currentPc = pc;
    var outerFunctionType = _enclosingExecutableElementSecurityType;
    _enclosingExecutableElementSecurityType = getSecurityType(node);

    var result = super.visitConstructorDeclaration(node);

    _enclosingExecutableElementSecurityType = outerFunctionType;
    pc = currentPc;
    return result;
  }

  @override
  bool visitIfStatement(IfStatement node) {
    //visit the if node
    node.condition.accept(this);
    var secType = getSecurityType(node.condition);
    //increase the pc
    var currentPc = pc;
    pc = pc.join(secType.label);

    //visit both branches
    node.thenStatement.setProperty(SEC_PC_PROPERTY, pc);
    node.thenStatement.accept(this);

    if (node.elseStatement != null) {
      node.elseStatement.setProperty(SEC_PC_PROPERTY, pc);
      node.elseStatement.accept(this);
    }
    pc = currentPc;
    return true;
  }

  @override
  bool visitForStatement(ForStatement node) {
    if (node.condition != null) {
      node.condition.accept(this);
      var secType = getSecurityType(node.condition);
      //increase the pc
      var currentPc = pc;
      pc = pc.join(secType.label);

      //visit both branches
      node.body.accept(this);

      pc = currentPc;
    }
    if (node.variables != null) {
      node.variables.accept(this);
    }
    //eg. for(1+3;;){}
    if (node.initialization != null) {
      node.initialization.accept(this);
    }
    if (node.updaters != null) {
      node.updaters.accept(this);
    }
    return true;
  }
}

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
class SecurityCheckerVisitor extends AbstractSecurityVisitor {
  //The implementation of the security type system
  final GradualSecurityTypeSystem secTypeSystem;

  SecurityCheckerVisitor(this.secTypeSystem, AnalysisErrorListener reporter,
      SecurityLabel globalPc, SecurityCache securityMap)
      : super(reporter, securityMap) {
    pc = globalPc;
  }

  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    //do local analysis for methods and fields.
    node.visitChildren(this);

    var result = true;

    //check that methods "refine" security signature.
    final type = node.element.supertype;
    if (type.name != "Object") {
      final currentClass = node.element;
      //final parentClassSecurityType = securityMap.map[parentClass] as
      //InterfaceSecurityType;

      final securityClassElement =
          node.getProperty(SECURITY_ELEMENT) as SecurityClassElement;
      //TODO: fix this
      currentClass.methods.forEach((MethodElement md) {
        final localMd = node.getMethod(md.name);
        result = _checkMethodOverrideConstrains(
                localMd,
                securityClassElement
                    .lookUpInheritedMethod(md.name, _library)
                    .methodType) &&
            result;
      });
    }
    return result;
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    //visit the function expression
    node.function.accept(this);
    node.argumentList.accept(this);

    //get the function sec type
    var fSecType = getSecurityType(node.function);
    if (fSecType is SecurityFunctionType) {
      SecurityFunctionType functionSecType = fSecType;
      var beginLabel = functionSecType.beginLabel;
      var endLabel = functionSecType.endLabel;
      //the current pc (joined with the function label) must be
      //less or equal than the function static pc (beginLabel)
      if (!(pc.join(endLabel).lessOrEqThan(beginLabel))) {
        //personalization of errors
        if (!pc.lessOrEqThan(beginLabel)) {
          reportError(
              SecurityTypeError.getBadFunctionCall(node, pc, beginLabel));
        }
        if (!endLabel.lessOrEqThan(beginLabel)) {
          reportError(SecurityTypeError.getBadLatentConstraintAtFunctionCall(
              node, endLabel, beginLabel));
        }
        return false;
      }
      //foreach function formal argument type, ensure each actual argument
      // type is a subtype
      _checkArgumentList(node.argumentList, functionSecType);
    } else if (isFunctionInstance(node.function)) {
      //if the invocation is to a Function instance, we do not have anything
      //to check
    }

    return true;
  }

  //this apply to a.f() and f().
  @override
  bool visitMethodInvocation(MethodInvocation node) {
    //case: method invocation over object instance (eg.  a.f(1))
    var fSecType = null;
    if (node.target != null) {
      node.target.accept(this);

      final SecurityType receiverSecType = getSecurityType(node.target);
      if (receiverSecType is DynamicSecurityType) {
        return true;
      }
      //find the type
      fSecType = (receiverSecType as InterfaceSecurityType)
          .getMethodSecurityType(node.methodName.staticElement.name);
    } else {
      //visit the function expression
      node.function.accept(this);

      // get the function sec type.
      fSecType = getSecurityType(node.function);
      if (fSecType is DynamicSecurityType ||
          isFunctionInstance(node.function)) {
        return true;
      }
    }
    node.argumentList.accept(this);

    if (fSecType is SecurityFunctionType) {
      SecurityFunctionType functionSecType = fSecType;
      var beginLabel = functionSecType.beginLabel;
      var endLabel = functionSecType.endLabel;
      //the current pc (joined with the function label) must be
      //less or equal than the function static pc (beginLabel)
      if (!(pc.join(endLabel).lessOrEqThan(beginLabel))) {
        //personalization of errors
        if (!pc.lessOrEqThan(beginLabel)) {
          reportError(
              SecurityTypeError.getBadFunctionCall(node, pc, beginLabel));
        }
        if (!endLabel.lessOrEqThan(beginLabel)) {
          reportError(SecurityTypeError.getBadLatentConstraintAtFunctionCall(
              node, endLabel, beginLabel));
        }
        return false;
      }

      //foreach function formal argument type, ensure each actual argument
      //type is a subtype
      _checkArgumentList(node.argumentList, functionSecType);
    }
    return true;
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    //check argument expressions
    node.argumentList.accept(this);

    //the security type for this node was already computed, so we can access
    //to the constructor name hare and gets its security type
    InterfaceSecurityType classSecType = getSecurityType(node);
    SecurityFunctionType functionSecType = classSecType
        .getConstructorSecurityType(node.staticElement.name, _library);

    var beginLabel = functionSecType.beginLabel;
    var endLabel = functionSecType.endLabel;
    //the current pc (joined with the function label) must be
    //less or equal than the function static pc (beginLabel)
    if (!(pc.join(endLabel).lessOrEqThan(beginLabel))) {
      //personalization of errors
      if (!pc.lessOrEqThan(beginLabel)) {
        reportError(SecurityTypeError.getBadFunctionCall(node, pc, beginLabel));
      }
      if (!endLabel.lessOrEqThan(beginLabel)) {
        reportError(SecurityTypeError.getBadLatentConstraintAtFunctionCall(
            node, endLabel, beginLabel));
      }
      return false;
    }
    //foreach function formal argument type, ensure each actual argument
    //type is a subtype
    _checkArgumentList(node.argumentList, functionSecType);
    return true;
  }

  void _checkArgumentList(
      ArgumentList node, SecurityFunctionType functionSecType) {
    for (int i = 0; i < node.arguments.length; i++) {
      final Expression expr = node.arguments[i];
      var secTypeFormalArg = functionSecType.argumentTypes[i];

      _checkSubtype(expr, getSecurityType(expr), secTypeFormalArg);
    }
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    node.visitChildren(this);

    //check that all assignments for initialization are ok
    for (VariableDeclaration variable in node.variables) {
      if (variable.initializer != null) {
        _checkAssignment(variable.initializer, variable);
      }
    }
    return true;
  }

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    //check security of both expressions
    node.leftHandSide.accept(this);
    node.rightHandSide.accept(this);

    _checkAssignment2(node);
    _checkAssignment2(node);
    return true;
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      node.expression.accept(this);
      var secType = getSecurityType(node.expression);

      var functionSecType = _enclosingExecutableElementSecurityType;
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
    var secType = getSecurityType(node.condition);
    //increase the pc
    var currentPc = pc;
    pc = pc.join(secType.label);
    //visit both branches
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);

    pc = currentPc;

    return true;
  }

  @override
  bool visitForEachStatement(ForEachStatement node) {
    node.visitChildren(this);
    //check that iterable expression can flow to identifier
    _checkAssignment(node.iterable, node.loopVariable);
    return true;
  }

  /**
   * Checks that an expression can be assigned to a type
   */
  void _checkAssignment(Expression expr, AstNode node, {SecurityType from}) {
    if (from == null) {
      from = getSecurityType(expr);
    }
    final secTypeVariable = getSecurityType(node);
    // fromT <: toT, no coercion needed.
    if (!secTypeSystem.isSubtypeOf(from, secTypeVariable)) {
      reportError(
          SecurityTypeError.getExplicitFlowError(node, from, secTypeVariable));
      return;
    }
    if (!pc.canRelabeledTo(secTypeVariable.label)) {
      reportError(SecurityTypeError.getImplicitFlowError(
          node, node, pc, secTypeVariable));
    }
  }

  void _checkAssignment2(AssignmentExpression node) {
    SecurityType to = getSecurityType(node.leftHandSide);
    SecurityType from = getSecurityType(node.rightHandSide);

    if (!secTypeSystem.isSubtypeOf(from, to)) {
      reportError(SecurityTypeError.getExplicitFlowError(node, from, to));
      return;
    }
    if (!pc.canRelabeledTo(to.label)) {
      reportError(SecurityTypeError.getImplicitFlowError(
          node, node.leftHandSide, pc, to));
    }
  }

  void _checkSubtype(Expression expr, SecurityType from, SecurityType to) {
    if (secTypeSystem.isSubtypeOf(from, to)) {
      var labelTo = to.label;
      //var labelFrom = _getLabel(from);
      if (pc.canRelabeledTo(labelTo)) return;
    }
    reportError(SecurityTypeError.getExplicitFlowError(expr, from, to));
  }

  bool _checkMethodOverrideConstrains(
      MethodDeclaration localMd, SecurityFunctionType superMdSecType) {
    final localMdSecType = getSecurityType(localMd) as SecurityFunctionType;

    if (!localMdSecType.returnType.label
        .lessOrEqThan(superMdSecType.returnType.label)) {
      reportError(SecurityTypeError.getInvalidOverrideReturnLabel(
          localMd,
          localMdSecType.returnType.label.toString(),
          superMdSecType.returnType.label.toString()));
      return false;
    }

    //TODO: Personalize error for latent constraints
    //TODO: Personalize error for arguments label parameter constraints
    if (!secTypeSystem.isSubtypeOf(localMdSecType, superMdSecType))
      reportError(SecurityTypeError.getInvalidMethodOverride(localMd));

    return false;
  }
}
