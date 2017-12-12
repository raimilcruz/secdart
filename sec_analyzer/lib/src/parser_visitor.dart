import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
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
  final AnalysisErrorListener reporter;

  /**
   * The parser used to get label from annotation
   */
  SecAnnotationParser _parser;
  /**
   * A helper parser to extract the function annotated security type
   */
  SecurityTypeHelperParser functionSecTypeParser;



  SecurityParserVisitor(this.reporter) {
    _parser = new FlatLatticeParser(reporter);
    functionSecTypeParser = new SecurityTypeHelperParser(_parser,reporter);
  }
  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    var secType = functionSecTypeParser.getFunctionSecType(node);
    node.setProperty(SEC_TYPE_PROPERTY, secType);

    super.visitFunctionDeclaration(node);
    return true;
  }

  @override
  bool visitFormalParameterList(FormalParameterList node) {
    for (FormalParameter pElem in node.parameters) {
      var secType = _getSecurityType(pElem);
      pElem.setProperty(SEC_TYPE_PROPERTY, secType);
    }
    return true;
  }

  SecurityType _getSecurityType(FormalParameter parameter) {
    DartType type = parameter.element.type;
    if(parameter is SimpleFormalParameter){
      var label =  functionSecTypeParser.getSecurityAnnotationForFunctionParameter(parameter);
      return new GroundSecurityType(type,label);
    }
    if(parameter is FunctionTypedFormalParameter){
      return _getDynamicSecurityType(type);
    }
    return new GroundSecurityType(type, new DynamicLabel());
  }
  SecurityType _getDynamicSecurityType(DartType dartType){
    if(dartType is FunctionType){
      FunctionType sft =  dartType;
      return new SecurityFunctionType(new DynamicLabel(),
          sft.typeArguments.map((t)=> _getDynamicSecurityType(t)).toList(),
          _getDynamicSecurityType(sft.returnType),
          new DynamicLabel());
    }
    return new GroundSecurityType(dartType, new DynamicLabel());
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    var secType;
    for (VariableDeclaration variable in node.variables) {
      //TODO: TO have a method more specif for that
      secType = _getSecurityTypeForBaseType(variable.element.type,node);
      variable.setProperty(SEC_TYPE_PROPERTY, secType);
    }
    node.visitChildren(this);
    return true;
  }
  SecurityType _getSecurityTypeForBaseType(DartType type,
      VariableDeclarationList node) {
    var label = functionSecTypeParser.getSecurityLabelVarOrParameter(node.metadata,node);
    return new GroundSecurityType(type, label);
  }

  DartType getDartType(TypeName name) {
    return (name == null) ? DynamicTypeImpl.instance : name.type;
  }
}

