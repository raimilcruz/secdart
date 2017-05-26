//The visitor in this file reports errors if the the analyzed source code
// contains features that are not supported for the security analysis

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:secdart_analyzer_plugin/src/errors.dart';

//TODO: Change the implementation of this class to avoid overriding each of the unsupported visitX methods for feature X.
class SupportedDartSubsetVisitor extends GeneralizingAstVisitor<Object>{
  final AnalysisErrorListener reporter;

  SupportedDartSubsetVisitor(this.reporter);

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    _reportUnsupportedDartFeature(node, "class");
    return null;
  }
  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    _reportUnsupportedDartFeature(node, "type alias");
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    _reportUnsupportedDartFeature(node, "enum");
    return null;
  }

  @override
  Object visitThrowExpression(ThrowExpression node) {
    _reportUnsupportedDartFeature(node, "throw exception");
    return null;
  }
  @override
  Object visitCatchClause(CatchClause node) {
    _reportUnsupportedDartFeature(node, "catch");
    return null;
  }


  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    _reportUnsupportedDartFeature(node, "function type alias");
    return null;
  }


  void _reportUnsupportedDartFeature(AstNode node,String nodeDisplyName){
    AnalysisError error =  SecurityTypeError.toAnalysisError(node, ImplementationErrorCode.UNSUPPORTED_DART_FEATURE, [nodeDisplyName]);
    reporter.onError(error);
  }
}
