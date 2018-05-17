import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:security_transformer/src/context.dart';

/// Necessary to create a different source name in parseCompilationUnit.
/// This is necessary, if use the same source name with the same AnalysisContext
/// all the time, the parseCompilationUnit will start failing.
int counter = 0;

void addStatementAfterStatement(Statement target, Statement newStatement) {
  final targetParent = target.parent;
  if (targetParent is Block) {
    final statements = targetParent.statements;
    final newStatements = <Statement>[];
    for (var i = 0; i < statements.length; i++) {
      final statement = statements[i];
      newStatements.add(statement);
      if (statement == target) {
        newStatements.add(newStatement);
      }
    }
    final newBlock = createBlock(newStatements);
    replaceNodeInAst(targetParent, newBlock);
  } else {
    final newBlock = createBlock(<Statement>[target, newStatement]);
    replaceNodeInAst(target, newBlock, parent: targetParent);
  }
}

void addStatementBeforeStatement(Statement target, Statement newStatement) {
  final targetParent = target.parent;
  if (targetParent is Block) {
    final statements = targetParent.statements;
    final newStatements = <Statement>[];
    for (var i = 0; i < statements.length; i++) {
      final statement = statements[i];
      if (statement == target) {
        newStatements.add(newStatement);
      }
      newStatements.add(statement);
    }
    final newBlock = createBlock(newStatements);
    replaceNodeInAst(targetParent, newBlock);
  } else {
    final newBlock = createBlock(<Statement>[newStatement, target]);
    replaceNodeInAst(target, newBlock, parent: targetParent);
  }
}

Block createBlock(List<Statement> statements) {
  return createBlockFunctionBody(statements).block;
}

BlockFunctionBody createBlockFunctionBody(List<Statement> statements) {
  StringBuffer buffer = new StringBuffer();
  for (var _ = 0; _ < statements.length; _++) {
    buffer.write(';');
  }
  final blockFunctionBody = parseBlockFunctionBody('${buffer.toString()}');
  for (var i = 0; i < statements.length; i++) {
    replaceNodeInAst(blockFunctionBody.block.statements[i], statements[i]);
  }
  return blockFunctionBody;
}

TypeName createDynamicTypeName() {
  return createTypeName('dynamic');
}

ExpressionStatement createExpressionStatementWithFunctionInvocation(
    String functionName, Iterable<String> arguments) {
  return parseStatement('$functionName(${arguments.join(', ')});');
}

ExpressionStatement
    createExpressionStatementWithLambdaWithSingleReturnExpression(
        Expression expression) {
  return parseStatement('() => $expression');
}

Expression createFunctionInvocation(
    String functionName, Iterable<String> arguments) {
  return createExpressionStatementWithFunctionInvocation(
          functionName, arguments)
      .expression;
}

FunctionExpression createLambdaWithSingleReturnExpression(
    Expression expression) {
  return createExpressionStatementWithLambdaWithSingleReturnExpression(
          expression)
      .expression;
}

ReturnStatement createReturnStatementWithExpression(Expression expression) {
  return parseStatement('return $expression');
}

ExpressionStatement createStatementExpressionWithExpression(
    Expression expression) {
  return parseStatement(expression.toString());
}

Expression parseExpression(String code) {
  ExpressionStatement statement = parseStatement("$code;");
  return statement.expression;
}

MethodInvocation createGetFieldInvocation(
    String prefix, String period, String identifier,
    {String className}) {
  return className != null
      ? parseExpression(
          "$prefix${period}getField('$identifier', type:$className)")
      : parseExpression("$prefix${period}getField('$identifier')");
}

MethodInvocation createInvokeInvocation(
    String prefix, String period, String identifier, List<String> arguments,
    {String className}) {
  return className != null
      ? parseExpression(
          "$prefix${period}invoke('$identifier', [${arguments.join(
          ', ')}], type:$className)")
      : parseExpression(
          "$prefix${period}invoke('$identifier', [${arguments.join(
          ', ')}])");
}

TypeName createTypeName(String type) {
  final declarationList = createVariableDeclarationList(type, ['a']);
  return declarationList.type;
}

VariableDeclarationList createVariableDeclarationList(
    String type, Iterable<String> identifiers) {
  return createVariableDeclarationStatement(type, identifiers).variables;
}

VariableDeclarationStatement createVariableDeclarationStatement(
    String type, Iterable<String> identifiers) {
  return parseStatement('$type ${identifiers.join(', ')};');
}

BlockFunctionBody parseBlockFunctionBody(String code) {
  final content = 'void _() {$code}';
  final compilationUnit = parseCompilationUnit(content);
  return (compilationUnit.declarations.first as FunctionDeclaration)
      .functionExpression
      .body;
}

CompilationUnit parseCompilationUnit(String contents, {String name}) {
  //@JPaulsen the name of the source cannot contains "<" because it makes
  //the source name a Windows-file invalid name.
  if (name == null) name = 'unknown source${++counter}';
  var source = new StringSource(contents, name);
  return resolveCompilationUnit2Helper(source);
}

Statement parseStatement(String code) {
  return parseBlockFunctionBody(code).block.statements.first;
}

TopLevelVariableDeclaration parseTopLevelVariableDeclaration(
    String type, String varName, String rightSideExpression) {
  final content = '$type $varName = $rightSideExpression';
  final compilationUnit = parseCompilationUnit(content);
  return compilationUnit.declarations.first;
}

VariableDeclarationStatement parseVariableDeclarationStatement(
    String type, String varName, String rightSideExpression) {
  final content = '$type $varName = $rightSideExpression';
  return parseStatement(content);
}

void replaceNodeInAst(AstNode oldNode, AstNode newNode, {AstNode parent}) {
  final replacer = new NodeReplacer(oldNode, newNode);
  parent ??= oldNode.parent;
  parent.accept(replacer);
}
