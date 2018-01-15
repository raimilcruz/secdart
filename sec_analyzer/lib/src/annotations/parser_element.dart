import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/security_type.dart';
import 'package:secdart_analyzer/src/security_label.dart';

class ElementAnnotationParserHelper {
  FlatLatticeParser _parser;
  ElementAnnotationParserHelper([bool intervalMode = false]) {
    _parser = new FlatLatticeParser(new ErrorCollector(), intervalMode);
  }

  SecurityFunctionType getFunctionSecType2(
      FunctionElement element, List<ParameterElement> parameters) {
    var metadataList =
        element.metadata.map((m) => (m as ElementAnnotationImpl).annotationAst);

    //label are dynamic by default
    var returnLabel = _parser.dynamicLabel;
    var beginLabel = _parser.dynamicLabel;
    var endLabel = _parser.dynamicLabel;
    if (metadataList != null) {
      var latentAnnotations =
          metadataList.where((a) => a.name.name == FUNCTION_LATENT_LABEL);

      if (latentAnnotations.length == 1) {
        Annotation securityFunctionAnnotation = latentAnnotations.first;
        var funAnnotationLabel =
            _parser.parseFunctionLabel(securityFunctionAnnotation);
        beginLabel = funAnnotationLabel.getBeginLabel();
        endLabel = funAnnotationLabel.getEndLabel();
      }

      var returnAnnotations = metadataList.where((a) => _parser.isLabel(a));
      if (returnAnnotations.length == 1) {
        returnLabel = _parser.parseLabel(returnAnnotations.first);
      }
    }
    var parameterSecTypes = new List<SecurityType>();
    for (ParameterElement p in parameters) {
      parameterSecTypes.add(getLabelScheme(p));
    }
    //TODO: This is not ok for functions
    var returnType = new GroundSecurityType(returnLabel);
    return new SecurityFunctionType(
        beginLabel, parameterSecTypes, returnType, endLabel);
  }

  SecurityType getLabelScheme(ParameterElement node) {
    return getSecurityTypeForParameter(node);
  }

  SecurityType getSecurityTypeForParameter(ParameterElement node) {
    var label = getSecurityLabel(node);
    //case where the parameter is a function type
    if (node.type is FunctionType) {
      FunctionType functionType = node.type;
      return new SecurityFunctionType(
          new DynamicLabel(),
          functionType.parameters
              .map((t) => getSecurityTypeForParameter(t))
              .toList(),
          new GroundSecurityType(new DynamicLabel()),
          label);
    }
    return new GroundSecurityType(label);
  }

  SecurityLabel getSecurityLabel(ParameterElement parameter) {
    var secLabelAnnotations = parameter.metadata
        .map((e) => (e as ElementAnnotationImpl).annotationAst)
        .where((x) => _parser.isLabel(x));
    var label = _parser.dynamicLabel;
    if (secLabelAnnotations.length == 1) {
      label = _parser.parseLabel(secLabelAnnotations.first);
    }
    return label;
  }

  SecurityType securityTypeForFunctionElement(FunctionElement staticElement) {
    return getFunctionSecType2(staticElement, staticElement.parameters);
  }

  SecurityType securityTypeForLocalVariable(
      LocalVariableElement staticElement) {
    var labelAnnotations = staticElement.metadata
        .map((e) => (e as ElementAnnotationImpl).annotationAst)
        .where((a) => _parser.isLabel(a));
    var label = _parser.dynamicLabel;
    if (labelAnnotations.length == 1) {
      label = _parser.parseLabel(labelAnnotations.first);
    }
    return new GroundSecurityType(label);
  }
}
