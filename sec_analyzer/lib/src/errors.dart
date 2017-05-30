import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
/// Analysis error results.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/task/model.dart';

/// Error code used for Sample warnings.
/*class MyErrorCode extends ErrorCode {
  static const MyErrorCode MY_WARNING_CODE =  const MyErrorCode('MY_WARNING_CODE', 'My sample warning');

  const MyErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
*/
/// Analysis error results.
final ListResultDescriptor<AnalysisError> SECURITY_TYPING_ERRORS =
new ListResultDescriptor<AnalysisError>(
    'SECURITY_TYPING_ERRORS', AnalysisError.NO_ERRORS);

/**
 * A helper class with static methods to report errors
 */
class SecurityTypeError{
  static AnalysisError toAnalysisError(AstNode node, ErrorCode code, arguments) {
    int begin = node is AnnotatedNode
        ? (node as AnnotatedNode).firstTokenAfterCommentAndMetadata.offset
        : node.offset;
    int length = node.end - begin;
    var source = (node.root as CompilationUnit).element.source;
    return new AnalysisError(source, begin, length, code, arguments);
  }
  static AnalysisError getImplementationError(AstNode expr,String message){
    var errorCode = SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR;
    var arguments = new List<Object>();
    arguments.add(message);
    return toAnalysisError(expr,errorCode,arguments);

  }

  static AnalysisError getExplicitFlowError(AstNode expr, DartType from,DartType to){
    var errorCode = SecurityErrorCode.EXPLICIT_FLOW;
    return toAnalysisError(expr,errorCode,null);

  }
  static AnalysisError getReturnTypeError(ReturnStatement node,DartType from, DartType to){
    var errorCode = SecurityErrorCode.RETURN_TYPE_ERROR;
    return toAnalysisError(node,errorCode,null);
  }
  static AnalysisError getFunctionLabelError(FunctionDeclaration node){
    var errorCode = SecurityErrorCode.FUNCTION_LABEL_ERROR;
    return toAnalysisError(node,errorCode,null);
  }

  static AnalysisError getBadFunctionCall(Expression node) {
    var errorCode = SecurityErrorCode.INVALID_FUNCTION_CALL;
    return toAnalysisError(node,errorCode,null);
  }

  static AnalysisError getDuplicatedLatentError(FunctionDeclaration node) {
    var errorCode = SecurityErrorCode.DUPLICATED_FUNCTION_LATENT_ERROR;
    return toAnalysisError(node,errorCode,null);
  }
  static AnalysisError getDuplicatedReturnLabelError(FunctionDeclaration node) {
    var errorCode = SecurityErrorCode.DUPLICATED_RETURN_LABEL_ERROR;
    return toAnalysisError(node,errorCode,null);
  }
  static AnalysisError getDuplicatedLabelOnParameterError(AstNode node) {
    var errorCode = SecurityErrorCode.DUPLICATED_LABEL_ON_PARAMETER_ERROR;
    return toAnalysisError(node,errorCode,null);
  }
  
  static AnalysisError getDummyError(CompilationUnitElement expr){
    var errorCode = SecurityErrorCode.MY_WARNING_CODE;
    var source = expr.source;
    return new AnalysisError(source, 0, 2, errorCode, null);        
  }
}

/**
 * Security [ErrorCode]s reported for the security analysis
 */
class SecurityErrorCode extends ErrorCode{

  static const SecurityErrorCode INTERNAL_IMPLEMENTATION_ERROR =
  const SecurityErrorCode(
      'INTERNAL_IMPLEMENTATION_ERROR', 'Internal implementarion error: {0}');

  /**
   * Error reported when a subtyping contraint (ST1 <: ST2) fails! (e.g. invalid direct assignment)
   */
  static const SecurityErrorCode EXPLICIT_FLOW =
  const SecurityErrorCode(
      'EXPLICIT_FLOW', 'Information flow leak');

/** 
 * Reported when the label of the returned value is not less than declared function return label
*/
  static const SecurityErrorCode RETURN_TYPE_ERROR =
  const SecurityErrorCode(
      'RETURN_TYPE_ERROR', 'Label of returned expression is higher than return label of the function or method');

  static const SecurityErrorCode FUNCTION_LABEL_ERROR =
  const SecurityErrorCode(
      'FUNCTION_LABEL_ERROR', 'Return type label must be smaller than end label');

  static const SecurityErrorCode INVALID_FUNCTION_CALL =
  const SecurityErrorCode(
      'INVALID_FUNCTION_CALL', 'Pc is not enough to invoke the function');

  static const SecurityErrorCode DUPLICATED_FUNCTION_LATENT_ERROR =
  const SecurityErrorCode(
      'DUPLICATED_FUNCTION_LATENT_ERROR', 'Duplicated function latent label');

  static const SecurityErrorCode DUPLICATED_RETURN_LABEL_ERROR=
  const SecurityErrorCode(
      'DUPLICATED_RETURN_LABEL_ERROR', 'Duplicated return label for function');

  static const SecurityErrorCode DUPLICATED_LABEL_ON_PARAMETER_ERROR=
  const SecurityErrorCode(
      'DUPLICATED_LABEL_ON_PARAMETER_ERROR', 'Duplicated label on parameter');

  static const SecurityErrorCode MY_WARNING_CODE =  const SecurityErrorCode('MY_WARNING_CODE', 'This is a proof-of-concept error');


  const SecurityErrorCode(String name, String message, [String correction]) : super(name, message,correction);


  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;


  @override
  ErrorType get type => ErrorType.STATIC_WARNING;//new ErrorType("SECURITY_ERROR_TYPE",1000,ErrorSeverity.ERROR);
}
class ImplementationErrorCode extends ErrorCode{
  ImplementationErrorCode(String name, String message) : super(name, message);

  static const SecurityErrorCode UNSUPPORTED_DART_FEATURE=
  const SecurityErrorCode(
      'UNSUPPORTED_DART_FEATURE', '{0} is not supported by the security analyzer');

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;


  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
  
