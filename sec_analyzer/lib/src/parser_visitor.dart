import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/errors.dart';
import 'package:secdart_analyzer/src/security_type.dart';
import 'package:secdart_analyzer/src/security_label.dart';

const String SEC_TYPE_PROPERTY = "sec-type";

/*
It parses security elements, that is annotations of security labels
We do not need to manage scope since we do not change Dart scope,
We just need to re-process the AST to include security
annotations.
*/
class SecurityParserVisitor extends GeneralizingAstVisitor<bool>{
  static const String FUNCTION_LATTENT_LABEL = "latent";
  final AnalysisErrorListener reporter;

  /**
   * The parser used to get label from annotation
   */
  SecAnnotationParser _parser;

  /**
   * The mode define the internal representation of labels
   */
  final bool intervalMode;

  final bool astIsResolved;

  SecurityParserVisitor(this.reporter,[this.intervalMode = false,
    this.astIsResolved=true]) {
    _parser = new FlatLatticeParser(reporter,intervalMode);
  }
  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    var secType = getFunctionSecType(node);
    node.setProperty(SEC_TYPE_PROPERTY, secType);

    super.visitFunctionDeclaration(node);
    return true;
  }

  @override
  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    var secType = getLabelScheme(node);
    node.setProperty(SEC_TYPE_PROPERTY, secType);
    return true;
  }

  @override
  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var secType = getLabelScheme(node);
    node.setProperty(SEC_TYPE_PROPERTY, secType);
    return true;
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    var secType;
    for (VariableDeclaration variable in node.variables) {
      //TODO: TO have a method more specif for that
      var label = getSimpleSecurityLabel(node.metadata,node);
      secType = new GroundSecurityType(label);;
      variable.setProperty(SEC_TYPE_PROPERTY, secType);
    }
    node.visitChildren(this);
    return true;
  }

  DartType getDartTypeFromParameter(FormalParameter parameter) {
    if(astIsResolved)return parameter.element.type;
    return DynamicTypeImpl.instance;
  }

  DartType getFunctionDartReturnType(FunctionDeclaration node) {
    if(astIsResolved)return node.element.returnType;
    return DynamicTypeImpl.instance;
  }

  DartType getDartTypeFromVariable(VariableDeclaration node) {
    if(astIsResolved)return node.element.type;
    return DynamicTypeImpl.instance;
  }

  /**
   * Get the security annotation from a list of annotations
   */
  SecurityLabel getSimpleSecurityLabel(
      NodeList<Annotation> annotations,AstNode node){
    var labelAnnotations = annotations.where((a)=>_parser.isLabel(a));
    var label = _parser.dynamicLabel;
    if(labelAnnotations.length>1){
      reporter.onError(
          SecurityTypeError.getDuplicatedLabelOnParameterError(node));
      return null;
    }
    else if(labelAnnotations.length==1){
      label = _parser.parseLabel(labelAnnotations.first);
    }
    return label;
  }




  SecurityFunctionType getFunctionSecType(FunctionDeclaration node) {
    return getFunctionSecType2(node, node.functionExpression.parameters,
      getFunctionDartReturnType(node));
  }
  /**
   * Get the security annotation for a formal parameter.
   */
  SecurityLabel getSecurityLabel(FormalParameter parameter) {
    var secLabelAnnotations = parameter.metadata.where((x) =>
        _parser.isLabel(x));
    var label = _parser.dynamicLabel;
    if (secLabelAnnotations.length > 1) {
      reporter.onError(
          SecurityTypeError.getDuplicatedLabelOnParameterError(parameter));
      return null;
    }
    else if (secLabelAnnotations.length == 1) {
      label = _parser.parseLabel(secLabelAnnotations.first);
    }
    return label;
  }

  SecurityFunctionType getFunctionSecType2(dynamic node,
      FormalParameterList parameters, DartType funReturnType) {
    if(!(node is FunctionDeclaration) && !(node is FunctionTypedFormalParameter))
      return null;
    var metadataList = node.metadata;

    //label are dynamic by default
    var returnLabel = _parser.dynamicLabel;
    var beginLabel = _parser.dynamicLabel;
    var endLabel = _parser.dynamicLabel;
    if (metadataList != null) {
      var latentAnnotations = metadataList.where((a)=>
      a.name.name == FUNCTION_LATTENT_LABEL);

      if(latentAnnotations.length>1){
        reporter.onError(SecurityTypeError.getDuplicatedLatentError(node));
        return null;
      }
      else if(latentAnnotations.length==1) {
        Annotation securityFunctionAnnotation = latentAnnotations.first;
        var funAnnotationLabel =
        _parser.parseFunctionLabel(securityFunctionAnnotation);
        beginLabel = funAnnotationLabel.getBeginLabel();
        endLabel = funAnnotationLabel.getEndLabel();
      }

      var returnAnnotations = metadataList.where((a)=>_parser.isLabel(a));
      if(returnAnnotations.length>1){
        reporter.onError(SecurityTypeError.getDuplicatedLatentError(node));
        return null;
      }
      else if(returnAnnotations.length==1){
        returnLabel = _parser.parseLabel(returnAnnotations.first);
      }
    }
    var parameterSecTypes = new List<SecurityType>();
    for (FormalParameter p in parameters.parameters) {
      parameterSecTypes.add(getLabelScheme(p));
    }
    //TODO: This is not ok for functions
    var returnType = new GroundSecurityType(returnLabel);
    return new SecurityFunctionType(beginLabel, parameterSecTypes,
        returnType, endLabel);
  }
  SecurityType getLabelScheme(FormalParameter node) {
    return _getSecurityType(node);
  }
  SecurityType _getSecurityType(FormalParameter node){
    var label = getSecurityLabel(node);
    if(node is FunctionTypedFormalParameter){
      return new SecurityFunctionType(
          new DynamicLabel(),
          node.
            parameters.
              parameters.map((t)=> _getSecurityType(t)).toList(),
          new GroundSecurityType(new DynamicLabel()),
          label);
    }
    return new GroundSecurityType(label);
  }

}
class FunctionLabelScheme{
  SecurityLabel beginLabel;
  SecurityLabel endLabel;
  SecurityLabel returnLabel;
  List<SecurityLabel> argumentLabels;
  FunctionLabelScheme(this.beginLabel,this.argumentLabels,
    this.returnLabel,this.endLabel);
}

