import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:secdart_analyzer/sec_analyzer.dart';
import 'package:secdart_analyzer/src/security_type.dart';

/**
 * A helper class with static methods to report errors
 */
class SecurityTypeError {
  static AnalysisError toAnalysisError(
      AstNode node, ErrorCode code, List<Object> arguments) {
    int begin = node is AnnotatedNode
        ? node.firstTokenAfterCommentAndMetadata.offset
        : node.offset;
    int length = node.end - begin;
    var source = (node.root as CompilationUnit).element.source;
    return new AnalysisError(source, begin, length, code, arguments);
  }

  static AnalysisError getImplementationError(AstNode expr, String message) {
    var errorCode = SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR;
    var arguments = new List<Object>();
    arguments.add(message);
    return toAnalysisError(expr, errorCode, arguments);
  }

  static AnalysisError getExplicitFlowError(
      AstNode expr, SecurityType from, SecurityType to) {
    var errorCode = SecurityErrorCode.EXPLICIT_FLOW;
    return toAnalysisError(expr, errorCode,
        new List<Object>()..add(from.toString())..add(to.toString()));
  }

  static AnalysisError getImplicitFlowError(AstNode assignmentNode,
      AstNode leftHand, SecurityLabel pc, SecurityType to) {
    var errorCode = SecurityErrorCode.IMPLICIT_FLOW;
    return toAnalysisError(
        assignmentNode, errorCode, [pc.toString(), leftHand.toString(), to]);
  }

  static AnalysisError getReturnTypeError(
      ReturnStatement node, SecurityType from, SecurityType to) {
    var errorCode = SecurityErrorCode.RETURN_TYPE_ERROR;
    return toAnalysisError(node, errorCode, []);
  }

  static AnalysisError getFunctionLabelError(FunctionDeclaration node) {
    var errorCode = SecurityErrorCode.FUNCTION_LABEL_ERROR;
    return toAnalysisError(node, errorCode, []);
  }

  static AnalysisError getBadFunctionCall(
      Expression node, SecurityLabel currentPc, SecurityLabel functionPc) {
    var errorCode = SecurityErrorCode.INVALID_FUNCTION_CALL;
    return toAnalysisError(node, errorCode, [currentPc, functionPc]);
  }

  static AnalysisError getBadLatentConstraintAtFunctionCall(
      Expression node, SecurityLabel endLabel, SecurityLabel beginLabel) {
    var errorCode = SecurityErrorCode.INVALID_LATENT_CONSTRAINT_AT_FUN_CALL;
    return toAnalysisError(node, errorCode, [endLabel, beginLabel]);
  }

  static AnalysisError getDuplicatedLatentError(FunctionDeclaration node) {
    var errorCode = ParserErrorCode.DUPLICATED_FUNCTION_LATENT_ERROR;
    return toAnalysisError(node, errorCode, []);
  }

  static AnalysisError getDuplicatedReturnLabelError(FunctionDeclaration node) {
    var errorCode = ParserErrorCode.DUPLICATED_RETURN_LABEL_ERROR;
    return toAnalysisError(node, errorCode, []);
  }

  static AnalysisError getDuplicatedLabelOnParameterError(AstNode node) {
    var errorCode = ParserErrorCode.DUPLICATED_LABEL_ON_PARAMETER_ERROR;
    return toAnalysisError(node, errorCode, []);
  }

  //SYNTACTIC ERRORS IN LABEL
  static AnalysisError getBadFunctionLabel(AstNode node) {
    var errorCode = ParserErrorCode.BAD_FUNCTION_LABEL;
    return toAnalysisError(node, errorCode, []);
  }

  static AnalysisError getCallNoFunction(AstNode node) {
    var errorCode = UnsupportedFeatureErrorCode.CALL_NO_FUNCTION;
    return toAnalysisError(node, errorCode, []);
  }

  static AnalysisError getUnsupportedDartFeature(AstNode node, String feature) {
    var errorCode = SecurityErrorCode.UNSUPPORTED_DART_FEATURE;
    return toAnalysisError(node, errorCode, [feature]);
  }

  //CLASS MEMBER ERRORS
  static AnalysisError getInvalidOverrideReturnLabel(MethodDeclaration md,
      String returnLabelOverridedMethod, String returnLabelSuperMethod) {
    var errorCode = SecurityErrorCode.INVAlID_OVERRIDE_RETURN_LABEL;
    return toAnalysisError(md, errorCode, [
      md.element.name,
      returnLabelOverridedMethod,
      (md.parent as ClassDeclaration).element.name,
      (md.parent as ClassDeclaration).element.supertype.element.name,
      returnLabelSuperMethod
    ]);
  }

  static AnalysisError getInvalidMethodOverride(MethodDeclaration md) {
    var errorCode = SecurityErrorCode.INVAlID_METHOD_OVERRIDE;
    return toAnalysisError(md, errorCode, [
      md.element.name,
      (md.parent as ClassDeclaration).element.name,
      (md.parent as ClassDeclaration).element.supertype.element.name
    ]);
  }
}

/**
 * Security [ErrorCode]s reported for the security analysis
 */
class SecurityErrorCode extends ErrorCode {
  static const SecurityErrorCode INTERNAL_IMPLEMENTATION_ERROR =
      const SecurityErrorCode('INTERNAL_IMPLEMENTATION_ERROR',
          'Internal implementarion error: {0}');

  /**
   * Error reported when a subtyping contraint (ST1 <: ST2) fails! (e.g. invalid direct assignment)
   */
  static const SecurityErrorCode EXPLICIT_FLOW = const SecurityErrorCode(
      'EXPLICIT_FLOW', 'Information flow leak from {0} to {1}');

  /**
   * Error reported when the PC is too high to do a low assignment
   */
  static const SecurityErrorCode IMPLICIT_FLOW = const SecurityErrorCode(
      'IMPLICIT_FLOW',
      'Pc "{0}" is higher than the security label of left hand '
      'expression "{1}" which is "{2}"');

/** 
 * Reported when the label of the returned value is not less than declared function return label
*/
  static const SecurityErrorCode RETURN_TYPE_ERROR = const SecurityErrorCode(
      'RETURN_TYPE_ERROR',
      'Label of returned expression is higher than return label of the function or method');

  static const SecurityErrorCode FUNCTION_LABEL_ERROR = const SecurityErrorCode(
      'FUNCTION_LABEL_ERROR',
      'Return type label must be smaller than end label');

  static const SecurityErrorCode INVALID_FUNCTION_CALL =
      const SecurityErrorCode(
          'INVALID_FUNCTION_CALL',
          'PC "{0}" at the invocation site '
          ' is higher than the function static PC (begin label: "{1}")');

  static const SecurityErrorCode INVALID_LATENT_CONSTRAINT_AT_FUN_CALL =
      const SecurityErrorCode(
          'INVALID_LATENT_CONSTRAINT_AT_FUN_CALL',
          'Function label "{0}" '
          ' is higher than the function static PC (begin label: "{1}").');

  static const SecurityErrorCode UNSUPPORTED_DART_FEATURE =
      const SecurityErrorCode('UNSUPPORTED_DART_FEATURE',
          '{0} is not supported by the security analyzer');

  static const SecurityErrorCode MY_WARNING_CODE = const SecurityErrorCode(
      'MY_WARNING_CODE', 'This is a proof-of-concept error');

  static const SecurityErrorCode INVAlID_OVERRIDE_RETURN_LABEL =
      const SecurityErrorCode(
          'INVAlID_OVERRIDE_RETURN_LABEL',
          'The return label of method "{0}" (ie. "{1}") in class "{2}" '
          'must be less than in class "{3}" (ie. "{4}")');

  static const SecurityErrorCode INVAlID_METHOD_OVERRIDE =
      const SecurityErrorCode(
          'INVAlID_METHOD_OVERRIDE',
          'The security signature of method "{0}" in class "{1}" '
          'is not a valid override for the security signature of the method '
          'in the class "{2}" (more details soon...)');

  const SecurityErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType
      .STATIC_WARNING; //new ErrorType("SECURITY_ERROR_TYPE",1000,ErrorSeverity.ERROR);
}

class UnsupportedFeatureErrorCode extends ErrorCode {
  static const UnsupportedFeatureErrorCode CALL_NO_FUNCTION =
      const UnsupportedFeatureErrorCode('CALL_NO_FUNCTION',
          'The expression in function position has dynamic type and we do not support dynamic functions');

  const UnsupportedFeatureErrorCode(String name, String message,
      [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType
      .STATIC_WARNING; //new ErrorType("SECURITY_ERROR_TYPE",1000,ErrorSeverity.ERROR);
}

class ParserErrorCode extends ErrorCode {
  static const ParserErrorCode DUPLICATED_FUNCTION_LATENT_ERROR =
      const ParserErrorCode('DUPLICATED_FUNCTION_LATENT_ERROR',
          'Duplicated function latent label');

  static const ParserErrorCode DUPLICATED_RETURN_LABEL_ERROR =
      const ParserErrorCode('DUPLICATED_RETURN_LABEL_ERROR',
          'Duplicated return label for function');

  static const ParserErrorCode DUPLICATED_LABEL_ON_PARAMETER_ERROR =
      const ParserErrorCode('DUPLICATED_LABEL_ON_PARAMETER_ERROR',
          'Duplicated label on parameter');

  static const ParserErrorCode BAD_FUNCTION_LABEL = const ParserErrorCode(
      'BAD_FUNCTION_LABEL',
      'Function label annotations must have two labels: '
      'the [endlabel] and the [beginlabel]');

  const ParserErrorCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}

class ImplementationErrorCode extends ErrorCode {
  ImplementationErrorCode(String name, String message) : super(name, message);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}

abstract class SecDartException implements Exception {
  String getMessage();
}

class UnsupportedFeatureException implements SecDartException {
  final String message;
  UnsupportedFeatureException([this.message]);

  @override
  String getMessage() => message;
}
