//The visitor in this file reports errors if the the analyzed source code
// contains features that are not supported for the security analysis

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:secdart_analyzer/src/errors.dart';

class UnSupportedDartSubsetVisitor extends GeneralizingAstVisitor<Object> {
  final AnalysisErrorListener reporter;

  UnSupportedDartSubsetVisitor(this.reporter);

  /*
  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    _reportError(node, "class");
    return null;
  }*/

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _reportError(node, "fields");
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    _reportError(node, "explicit constructor");
    return null;
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    _reportError(node, "type alias");
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    _reportError(node, "enum");
    return null;
  }

  @override
  Object visitThrowExpression(ThrowExpression node) {
    _reportError(node, "throw exception");
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
    _reportError(node, "catch");
    return null;
  }

  @override
  Object visitAwaitExpression(AwaitExpression node) =>
      _reportError(node, "await");

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    _reportError(node, "function type alias");
    return null;
  }

  //loops
  @override
  Object visitWhileStatement(WhileStatement node) =>
      _reportError(node, "while");

  @override
  Object visitYieldStatement(YieldStatement node) =>
      _reportError(node, "yield");

  @override
  Object visitBreakStatement(BreakStatement node) =>
      _reportError(node, "break");

  @override
  Object visitContinueStatement(ContinueStatement node) =>
      _reportError(node, "continue");

  //<-- end loops

  @override
  Object visitDoStatement(DoStatement node) =>
      _reportError(node, "do... while");

  @override
  Object visitForEachStatement(ForEachStatement node) =>
      _reportError(node, "foreach");

  @override
  Object visitForStatement(ForStatement node) => _reportError(node, "for");

  @override
  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      _reportError(node, "function declaration statement");

  @override
  Object visitRethrowExpression(RethrowExpression node) =>
      _reportError(node, "rethrow");

  @override
  Object visitSwitchStatement(SwitchStatement node) =>
      _reportError(node, "switch");

  @override
  Object visitTryStatement(TryStatement node) => _reportError(node, "try");

  void _reportError(AstNode node, String nodeDisplyName) {
    AnalysisError error =
        SecurityTypeError.getUnsupportedDartFeature(node, nodeDisplyName);
    reporter.onError(error);
    return null;
  }
}
