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

  SecurityLabel get dynamicLabel => _parser.dynamicLabel;

  SecurityFunctionType getFunctionSecType2(
      Iterable<Annotation> metadataList, List<ParameterElement> parameters) {
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
    return new SecurityFunctionTypeImpl(
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
      return new SecurityFunctionTypeImpl(
          dynamicLabel,
          functionType.parameters
              .map((t) => getSecurityTypeForParameter(t))
              .toList(),
          new GroundSecurityType(dynamicLabel),
          label);
    }
    if (node.type.element is ClassElement) {
      return securityTypeFromClass(node.type.element, label);
    }
    //it must be a function alias then
    return new DynamicSecurityType(label);
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

  SecurityType securityTypeForFunctionElement(FunctionElement element) {
    var metadataList =
        element.metadata.map((m) => (m as ElementAnnotationImpl).annotationAst);
    return getFunctionSecType2(metadataList, element.parameters);
  }

  SecurityType securityTypeForLocalVariable(
      LocalVariableElement staticElement) {
    var labelAnnotations = staticElement.metadata
        .map((e) => (e as ElementAnnotationImpl).annotationAst)
        .where((a) => _parser.isLabel(a));

    //TODO: If the local variable type is a user defined class with security
    //annotations, then we need to get that information.
    var label = _parser.dynamicLabel;
    if (labelAnnotations.length == 1) {
      label = _parser.parseLabel(labelAnnotations.first);
    }
    if (staticElement.type.element is ClassElement) {
      return securityTypeFromClass(staticElement.type.element, label);
    }
    //it must be a function alias then
    return new DynamicSecurityType(label);
  }

  SecurityType securityTypeFromClass(
      ClassElement classElement, SecurityLabel label) {
    if (classElement.name == 'bool' || classElement.name == 'int') {
      return new GroundSecurityType(label);
    }
    if (classElement.library.imports
            .where((import) => import.uri.contains("secdart.dart"))
            .length ==
        0) {
      //TODO: Get either a parametric version for the security type or
      //the unknown security type
      return new GroundSecurityType(label);
    }
    return new InterfaceSecurityTypeImpl(
        label, securityInfoFromClass(classElement));
  }

  ClassSecurityInfo securityInfoFromClass(ClassElement classElement) {
    Map<String, SecurityFunctionType> methodTypes =
        new Map<String, SecurityFunctionType>();
    classElement.methods.forEach((mElement) {
      var metadataList = mElement.metadata
          .map((m) => (m as ElementAnnotationImpl).annotationAst);
      methodTypes.putIfAbsent(mElement.name,
          () => getFunctionSecType2(metadataList, mElement.parameters));
    });
    return new ClassSecurityInfo(methodTypes);
  }
}
