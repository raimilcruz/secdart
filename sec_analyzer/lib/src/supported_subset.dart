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

  Object _reportError(AstNode node, String nodeDisplayName) {
    AnalysisError error =
        SecurityTypeError.getUnsupportedDartFeature(node, nodeDisplayName);
    reporter.onError(error);
    return null;
  }
}
