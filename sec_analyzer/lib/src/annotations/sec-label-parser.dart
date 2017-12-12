import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/analyzer.dart';
import '../security_label.dart';
import '../security-type.dart';
import '../errors.dart';

/**
 * An abstract parser for Dart annotations that represent security labels
 */
abstract class SecAnnotationParser{
  /**
   * When is implemented returns the dynamic label
   */
  get dynamicLabel;

  SecurityLabel parseLabel(Annotation n);
  FunctionAnnotationLabel parseFunctionLabel(Annotation n);

  isLabel(Annotation a);
}

class FlatLatticeParser extends SecAnnotationParser{
  AnalysisErrorListener errorListener;
  bool intervalMode;

  static const String FUNCTION_LATENT_LABEL = "latent";

  FlatLatticeParser(AnalysisErrorListener this.errorListener, [bool intervalMode = false]){
    this.intervalMode = intervalMode;
  }

  @override
  FunctionAnnotationLabel parseFunctionLabel(Annotation n) {
    // TODO: Report error in a proper way
    if(n.name.name != FUNCTION_LATENT_LABEL){
      errorListener.onError(SecurityTypeError.getDuplicatedLabelOnParameterError(n));
      throw new Exception();
    }
    var arguments = n.arguments.arguments;
    if(arguments.length!=2){
      errorListener.onError(SecurityTypeError.getBadFunctionLabel(n));
      throw new Error();
    }
    var beginLabelString = arguments[0] as SimpleStringLiteral;
    var endLabelString = arguments[1] as SimpleStringLiteral;

    var beginLabel = _parseFunctionLabelArgument(beginLabelString.stringValue);
    var endLabel = _parseFunctionLabelArgument(endLabelString.stringValue);
    return new FunctionAnnotationLabel(beginLabel,endLabel);
  }

  @override
  SecurityLabel parseLabel(Annotation n) {
    var annotationName = n.name.name;
    switch (annotationName) {
      case 'high':
        return new HighLabel();
      case 'low':
        return new LowLabel();
      case 'top':
        return new TopLabel();
      case 'bot':
        return new BotLabel();
      case 'dynl':
        return this.dynamicLabel;
      default:
        throw new SecCompilationException(
            "Annotation does not represent a label for me!");
    }
  }
  SecurityLabel _parseFunctionLabelArgument(String label) {
    switch (label) {
      case 'H':
        return new HighLabel();
      case 'L':
        return new LowLabel();
      case 'top':
        return new TopLabel();
      case 'bot':
        return new BotLabel();
      case 'dynl':
        return this.dynamicLabel;
      default:
        throw new SecCompilationException("String does not represent a label for me!");
    }
  }

  @override
  get dynamicLabel {
    if(intervalMode)
      return new IntervalLabel(new BotLabel(),new TopLabel());
    return new DynamicLabel();
  }


  @override
  isLabel(Annotation a) {
    switch (a.name.name) {
      case 'low':
      case 'high':
      case 'top':
      case 'bot':
      case 'dynl':
        return true;
      default:
        return false;
    }
  }
}
class FunctionAnnotationLabel{
  SecurityLabel beginLabel;
  SecurityLabel endLabel;
  FunctionAnnotationLabel(SecurityLabel this.beginLabel, SecurityLabel this.endLabel);

  SecurityLabel getBeginLabel()=> beginLabel;
  SecurityLabel getEndLabel()=> endLabel;
}
class SecurityTypeHelperParser{
  static const String FUNCTION_LATTENT_LABEL = "latent";

  SecAnnotationParser _parser;
  AnalysisErrorListener errorListener;

  SecurityTypeHelperParser(SecAnnotationParser this._parser, AnalysisErrorListener this.errorListener);

  SecurityFunctionType getFunctionSecType(FunctionDeclaration node) {
    var metadataList = node.metadata;

    //label are dynamic by default
    var returnLabel = _parser.dynamicLabel;
    var beginLabel = _parser.dynamicLabel;
    var endLabel = _parser.dynamicLabel;
    if (metadataList != null) {
      var latentAnnotations = metadataList.where((a)=>a.name.name == FUNCTION_LATTENT_LABEL);

      if(latentAnnotations.length>1){
        reportError(SecurityTypeError.getDuplicatedLatentError(node));
        return null;
      }
      else if(latentAnnotations.length==1) {
        Annotation securityFunctionAnnotation = latentAnnotations.first;
        var funAnnotationLabel = _parser.parseFunctionLabel(securityFunctionAnnotation);
        beginLabel = funAnnotationLabel.getBeginLabel();
        endLabel = funAnnotationLabel.getEndLabel();
      }

      var returnAnnotations = metadataList.where((a)=>_parser.isLabel(a));
      if(returnAnnotations.length>1){
        reportError(SecurityTypeError.getDuplicatedLatentError(node));
        return null;
      }
      else if(returnAnnotations.length==1){
        returnLabel = _parser.parseLabel(returnAnnotations.first);
      }
    }
    var parameterSecTypes = new List<SecurityType>();
    FunctionExpression functionExpr = node.functionExpression;
    var formalParameterlists = functionExpr.parameters.parameters;
    for (FormalParameter p in formalParameterlists) {
      //TODO: Have the option to receive especify label for function as parameter.
      SecurityLabel label = getSecurityAnnotationForFunctionParameter(p);
      parameterSecTypes.add(new GroundSecurityType(p.element.type, label));
    }
    var returnType = new GroundSecurityType(functionExpr.element.returnType, returnLabel);
    return new SecurityFunctionType(beginLabel, parameterSecTypes, returnType, endLabel);
  }

  /**
   * Get the security annotation from a list of annotations
   */
  SecurityLabel getSecurityLabelVarOrParameter(
      NodeList<Annotation> annotations,AstNode node){
    var labelAnnotations = annotations.where((a)=>_parser.isLabel(a));
    var label = _parser.dynamicLabel;
    if(labelAnnotations.length>1){
      errorListener.onError(SecurityTypeError.getDuplicatedLabelOnParameterError(node));
      return null;
    }
    else if(labelAnnotations.length==1){
      label = _parser.parseLabel(labelAnnotations.first);
    }
    return label;

  }
  /**
   * Get the security annotation for a function parameter
   */
  SecurityLabel getSecurityAnnotationForFunctionParameter(FormalParameter parameter) {
    var secLabelAnnotations = parameter.metadata.where((x)=> _parser.isLabel(x));
    var label = _parser.dynamicLabel;
    if(secLabelAnnotations.length>1){
      reportError(SecurityTypeError.getDuplicatedLabelOnParameterError(parameter));
      return null;
    }
    else if(secLabelAnnotations.length==1){
      label = _parser.parseLabel(secLabelAnnotations.first);
    }
    return label;
  }
  void reportError(AnalysisError explicitFlowError) {
    errorListener.onError(explicitFlowError);
  }
}
class SecCompilationException implements SecDartException{
  final String message;
  SecCompilationException([this.message]);

  @override
  String getMessage() => message;
}
