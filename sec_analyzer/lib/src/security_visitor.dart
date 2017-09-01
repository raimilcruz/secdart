import 'annotations/sec-label-parser.dart';
import 'errors.dart';
import 'gs-typesystem.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/dart/element/element.dart';

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'scope.dart';
import 'security-type.dart';
import 'security_label.dart';



final String SEC_TYPE_PROPERTY = "sec-type";


/**
 * This visitor performs an information-flow analysis over a resolved AST. The information-flow is based
 * in the security annotations of the code.
 * This implementation has taken a lot of code from CodeChecker (analyzer\src\task\strong\checker.dart)
 */
//TODO: Use a ScopedVisitor
class SecurityVisitor extends /*ScopedVisitor*/RecursiveAstVisitor<bool> {

  //The implementation of the security type system
  final GradualSecurityTypeSystem secTypeSystem;
  final AnalysisErrorListener reporter;
  final bool intervalMode;

  /**
   * The parser used to get label from annotation
   */
  SecAnnotationParser _parser;

  /**
   * A helper parser to extract the function annotated security type
   */
  SecurityTypeHelperParser functionSecTypeParser;

  /**
   * Map(id,SecType)
   */
  SecurityScope<SecurityType> _secScope;

  /**
   * The program counter label
   */
  SecurityLabel _pc = null;

  /**
   * The element representing the function containing the current node, or `null` if the
   * current node is not contained in a function.
   */
  ExecutableElement _enclosingFunction;
  FunctionDeclaration _enclosingFunctionDeclaration;

  SecurityVisitor(this.secTypeSystem, this.reporter,[bool this.intervalMode = false]) {
    //TODO: Change for LibraryScope
    _secScope = new NestedSecurityScope(new EmptySecurityScope<SecurityType>());
    _parser = new FlatLatticeParser(reporter);
    functionSecTypeParser = new SecurityTypeHelperParser(_parser,reporter);
  }

  bool visitCompilationUnit(CompilationUnit node) {
    try {
      node.visitChildren(this);
    } on SecDartException catch(e){
      reportError(SecurityTypeError.toAnalysisError(node,SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.getMessage()]));
    }
    return null;
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    /*TODO: Check here. We need a better way to add function declaration to the scope 
    eg. calls to function that are defined ahead
    */
    var secType = functionSecTypeParser.getFunctionSecType(node);
    if(_secScope.isDefined(node.name.name)) {
      reportError(_secScope.getErrorForDuplicate(node.name.name, node.element));
      return false;
    }
    _secScope.define(node.name.name,secType);

    _checkFunctionSecType(node,secType);

    //store the sectype of the node
    node.setProperty(SEC_TYPE_PROPERTY, secType);

    var currentPc = _pc;
    var currentScope = _secScope;
    ExecutableElement outerFunction = _enclosingFunction;
    _enclosingFunction = node.element;

    FunctionDeclaration outerFunctionDecl = _enclosingFunctionDeclaration;
    _enclosingFunctionDeclaration = node;


    _secScope = new SecurityFunctionScope(_secScope, node.element);

    _pc = (secType as SecurityFunctionType).beginLabel;


    var result = super.visitFunctionDeclaration(node);

    _enclosingFunction = outerFunction;
    _enclosingFunctionDeclaration = outerFunctionDecl;
    _pc = currentPc;
    _secScope = currentScope;
    return result;
  }



  @override
  bool visitFormalParameterList(FormalParameterList node) {
    for (FormalParameter pElem in node.parameters) {
      DartType type = pElem.element.type;
      String name = pElem.element.name;
      var label = functionSecTypeParser.getSecurityAnnotationForFunctionParameter(pElem);
      var secType = new GroundSecurityType(type, label);
      if(_secScope.isDefined(name)) {
        reportError(_secScope.getErrorForDuplicate(name, pElem.element));
        return false;
      }
      _secScope.define(name, secType);
    }    
  }
  
  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    //visit the function expression
    node.function.accept(this);
    //get the function sec type
    var functionSecType = _getSecurityType(node) as SecurityFunctionType;
    var beginLabel = functionSecType.beginLabel;
    var endLabel = functionSecType.endLabel;
    //check the pc is enough high to invoke the function
    if(beginLabel.canRelabeledTo(_pc.join(endLabel))){
      reportError(SecurityTypeError.getBadFunctionCall(node));
      return false;
    }

    node.argumentList.accept(this);

    checkArgummentList(node.argumentList,functionSecType);
    //foreach function formal argument type, ensure each actual argument type is a subtype
    node.setProperty(SEC_TYPE_PROPERTY,stampLabel(functionSecType.returnType,functionSecType.endLabel));
  }


  @override
  bool visitMethodInvocation(MethodInvocation node) {
    //visit the function expression
    node.function.accept(this);
    //get the function sec type. This does not work when the function is another file. We need to solve
    //the problems with the scope.
    var functionSecType = _getSecurityType(node.function) as SecurityFunctionType;
    var beginLabel = functionSecType.beginLabel;
    var endlabel = functionSecType.endLabel;
    //check the pc is enough high to invoke the funciton
    if(!(_pc.join(endlabel).lessOrEqThan(beginLabel))){
      reportError(SecurityTypeError.getBadFunctionCall(node));
      return false;
    }

    node.argumentList.accept(this);

    checkArgummentList(node.argumentList,functionSecType);
    //foreach function formal argument type, ensure each actual argument type is a subtype
    node.setProperty(SEC_TYPE_PROPERTY,stampLabel(functionSecType.returnType,functionSecType.endLabel));
  }

  SecurityType stampLabel(SecurityType type, SecurityLabel l){
    type.label = type.label.join(l);
    return type;
  }

  void checkArgummentList(ArgumentList node, SecurityFunctionType functionSecType) {
    NodeList<Expression> list = node.arguments;
    int len = list.length;
    for (int i = 0; i < len; ++i) {
      Expression expr = list[i];

      var secTypeFormalArg = functionSecType.argumentTypes[i];
      checkSubtype(expr,_getSecurityType(expr),secTypeFormalArg);
    }
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {

    TypeName type = node.type;

    var dartType = null;
    var secType = null;
    if (type != null) {
      dartType = getType(type);
      secType = _getSecurityTypeForBaseType(dartType, node);
    }
    //the security dart type


    for (VariableDeclaration variable in node.variables) {
      var initializer = variable.initializer;
      if (initializer != null) {
        //TODO: TO have a method more specif for that
        secType = _getSecurityTypeForBaseType(variable.element.type,node);
        //in the case the initializer  is constant, the label is the current pc at that moment
        initializer.accept(this);
        var initializerSecType = _getSecurityType(initializer);
        initializer.setProperty(SEC_TYPE_PROPERTY,initializerSecType);
        checkAssignment(initializer, secType,variable);
      }
      //add variable to the scope
      if(_secScope.isDefined(variable.name.name)) {
        reportError(_secScope.getErrorForDuplicate(variable.name.name, variable.element));
        return false;
      }
      _secScope.define(variable.name.name, secType);
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

    _checkAssignment2(node.leftHandSide,leftSecType,rigthSecType,node);
    return true;
  }

  @override
  bool visitIfStatement(IfStatement node) {
    //visit the if node
    var okCond = node.condition.accept(this);
    var secType = _getSecurityType(node.condition);
    //increase the pc
    var currentPc = _pc;
    _pc = _pc.join(_getLabel(secType));

    var currentScope = _secScope;
    _secScope = new NestedSecurityScope(_secScope);

    //visit both branches
    var okThenBranch = node.thenStatement.accept(this);

    _secScope = currentScope;

    var okElseBranch = true;
    if (node.elseStatement != null) {
      _secScope = new NestedSecurityScope(_secScope);

      okElseBranch = node.elseStatement.accept(this);

      _secScope = currentScope;
    }
    _pc = currentPc;
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

    var resultType = new GroundSecurityType(node.staticType, leftSecLabel.join(rightSecLabel));
    node.setProperty(SEC_TYPE_PROPERTY, resultType);
    return true;
  }

  /**
   * Given a [FunctionDeclaration] node returns the [SecurityFunctionType]. In the case
   * the function is not annotated with an explicit label, a default security label is
   * returned.
   */
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inGetterContext() && node.staticElement is ParameterElement) {
      //if this identifier is in getter context we can get from the scope
      var secType = _secScope.lookup(node.name);
      node.setProperty(SEC_TYPE_PROPERTY, secType);
    }
    else if (node.inGetterContext() && node.staticElement is LocalVariableElement) {
      //if this identifier is in getter context we can get from the scope
      var secType = _secScope.lookup(node.name);
      node.setProperty(SEC_TYPE_PROPERTY, secType);
    }
    //is in the left side of an assignment
    else if (node.inSetterContext() && node.staticElement is LocalVariableElement) {
      var secType = _secScope.lookup(node.name);
      node.setProperty(SEC_TYPE_PROPERTY, secType);
    }
    else if (node.inGetterContext() && node.staticElement is FunctionElement) {
      //access to a function
      var secType = _secScope.lookup(node.name);
      node.setProperty(SEC_TYPE_PROPERTY, secType);
    }
    return true;
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      node.expression.accept(this);
      var secType = _getSecurityType(node.expression);

      var functionSecType = _enclosingFunctionDeclaration.getProperty(
          SEC_TYPE_PROPERTY) as SecurityFunctionType;
      if (secTypeSystem.isSubtypeOf(secType,functionSecType.returnType)) {
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
    var okCond = node.condition.accept(this);
    var secType = _getSecurityType(node.condition);
    //increase the pc
    var currentPc = _pc;
    _pc = _pc.join(_getLabel(secType));

    var currentScope = _secScope;

    _secScope = new NestedSecurityScope(_secScope);
    //visit both branches
    var okThenBranch = node.thenExpression.accept(this);
    _secScope = currentScope;

    var okElseBranch = true;


    _secScope = new NestedSecurityScope(_secScope);
    okElseBranch = node.elseExpression.accept(this);
    _secScope = currentScope;

    var secTypeThenExpr = _getSecurityType(node.thenExpression);
    var secTypeElseExpr = _getSecurityType(node.elseExpression);

    //TODO: This is wrong for high order types
    var resultType = new GroundSecurityType(node.staticType, secTypeThenExpr.label.join(secTypeElseExpr.label).join(secType.label));
    node.setProperty(SEC_TYPE_PROPERTY, resultType);
    _pc = currentPc;
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    node.setProperty(
        SEC_TYPE_PROPERTY, new GroundSecurityType(node.staticType, _pc));
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    node.setProperty(
        SEC_TYPE_PROPERTY, new GroundSecurityType(node.staticType, _pc));
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    node.setProperty(
        SEC_TYPE_PROPERTY, new GroundSecurityType(node.staticType, _pc));
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node){
    node.expression.accept(this);
    node.setProperty(SEC_TYPE_PROPERTY, _getSecurityType(node.expression));
    return true;
  }

  /**
   * Given a [FunctionDeclaration] node returns its security type
   */






  /**
   * Checks that an expression can be assigned to a type
   */
  void checkAssignment(Expression expr, SecurityType type, VariableDeclaration node) {
    if (expr is ParenthesizedExpression) {
      checkAssignment(expr.expression, type,node);
    } else {
      _checkAssignment(expr, type,node);
    }
  }

  void _checkAssignment(Expression expr, SecurityType to,VariableDeclaration node, {SecurityType from}) {
    if (from == null) {
      from = _getSecurityType(expr);
    }

    // We can use anything as void.
    if (to.isVoid) return;

    // fromT <: toT, no coercion needed.
    if (secTypeSystem.isSubtypeOf(from, to)) {
      var labelTo = _getLabel(to);
      //var labelFrom = _getLabel(from);
      if (_pc.canRelabeledTo(labelTo)) return;
    }

    //TODO: Report error
    reportError(SecurityTypeError.getExplicitFlowError(node, to, from));
  }

  void _checkAssignment2(Expression expr, SecurityType to, SecurityType from,AssignmentExpression node) {
    if (secTypeSystem.isSubtypeOf(from, to)) {
      var labelTo = _getLabel(to);
      //var labelFrom = _getLabel(from);
      if (_pc.canRelabeledTo(labelTo)) return;
    }
    //TODO: Report error
    reportError(SecurityTypeError.getExplicitFlowError(node, to, from));
  }
  void checkSubtype(Expression expr, SecurityType from, SecurityType to) {
    if (secTypeSystem.isSubtypeOf(from, to)) {
      var labelTo = _getLabel(to);
      //var labelFrom = _getLabel(from);
      if (_pc.canRelabeledTo(labelTo)) return;
    }

    //TODO: Report error
    reportError(SecurityTypeError.getExplicitFlowError(expr, to, from));
  }

  /**
   * Get the label from a security type.
   */
  SecurityLabel _getLabel(SecurityType to) {
    if (!(to is GroundSecurityType)) {
      throw new UnsupportedFeatureException("Security type is not supported yet ${to.runtimeType}");
    }
    return (to as GroundSecurityType).label;
  }

  /**
   * Report an [AnalysisError] to the underline [AnalysisErrorListener]
   */
  void reportError(AnalysisError explicitFlowError) {
    reporter.onError(explicitFlowError);
  }

  DartType _getStaticType(Expression expr) {
    DartType t = expr.staticType ?? DynamicTypeImpl.instance;

    // Remove fuzzy arrow if possible.
    /*if (t is FunctionType && StaticInfo.isKnownFunction(expr)) {
      t = _removeFuzz(t);
    }*/

    return t;
  }

  /**
   * Get the security type associated to an expression. The security type need to be resolved for the expression
   */
  SecurityType _getSecurityType(Expression expr) {
    var result = expr.getProperty(SEC_TYPE_PROPERTY);
    if(result == null) {
      reportError(SecurityTypeError.toAnalysisError(expr,SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, "Expression does not "
          "have a security type (For instance it happens when a calling a function in another library, we do not how to deal"
          "with multiple file yet)"));
      throw new UnsupportedFeatureException("Error in SecurityVisitor._getSecurityType");
    }
    return result;
  }

  //TODO: Neet to Return a security type
  DartType getType(TypeName name) {
    return (name == null) ? DynamicTypeImpl.instance : name.type;
  }

  SecurityType _getSecurityTypeForBaseType(DartType type,
      VariableDeclarationList node) {
    if (type is SecurityType) {
      throw new ArgumentError("type must be an original DartType");
    }
    var label = functionSecTypeParser.getSecurityLabelVarOrParameter(node.metadata,node);
    return new GroundSecurityType(type, label);
  }


  void _checkFunctionSecType(FunctionDeclaration decl,SecurityFunctionType secType) {
    //TODO: Be careful. In the next implementation iteration we will deal with first class functions
    /*var returnLabel = (secType.returnType as GroundSecurityType).label;
    if(returnLabel.canRelabeledTo(secType.endLabel))
      return;
    reportError(SecurityTypeError.getFunctionLabelError(decl));
    */
    FormatException a;
  }
}








