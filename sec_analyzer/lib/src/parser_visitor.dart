import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/annotations/parser_element.dart';
import 'package:secdart_analyzer/src/errors.dart';
import 'package:secdart_analyzer/src/helper.dart';
import 'package:secdart_analyzer/src/security_type.dart';

/*
It parses security elements, that is annotations of security labels
We do not need to manage scope since we do not change Dart scope,
We just need to re-process the AST to include security
annotations.
*/
class SecurityParserVisitor extends GeneralizingAstVisitor<bool> {
  AnalysisErrorListener _reporter;

  /**
   * The parser used to get label from annotation
   */
  SecAnnotationParser _parser;
  ElementAnnotationParserImpl _elementParser;

  /**
   * The mode define the internal representation of labels
   */
  final bool intervalMode;

  final bool astIsResolved;

  SecurityParserVisitor(reporter, CompilationUnit unit,
      [this.intervalMode = false, this.astIsResolved = true]) {
    _reporter = reporter;
    _parser = new FlatLatticeParser(reporter, unit, intervalMode);
    _elementParser =
        new ElementAnnotationParserImpl(unit, reporter, intervalMode);
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    try {
      node.visitChildren(this);
    } on SecDartException catch (e) {
      var astNode =
          e.node != null && e.node.root is CompilationUnit ? e.node : node;
      _reporter.onError(SecurityTypeError.toAnalysisError(astNode,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.getMessage()]));
    } on Exception catch (e) {
      _reporter.onError(SecurityTypeError.toAnalysisError(node,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.toString()]));
    } catch (e) {
      _reporter.onError(SecurityTypeError.toAnalysisError(node,
          SecurityErrorCode.INTERNAL_IMPLEMENTATION_ERROR, [e.toString()]));
    }
    return true;
  }

  @override
  bool visitFieldDeclaration(FieldDeclaration node) {
    //we don't need to get here the annotation because the resolver will
    //do anyway
    _checkSimpleLabelAnnotation(node);
    //_elementParser.fromDartType(node.el, label)
    return true;
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    var secType = _getMethodSecType(node);
    node.setProperty(SEC_TYPE_PROPERTY, secType);

    super.visitMethodDeclaration(node);
    return true;
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    final secType = _getFunctionSecType(node);
    node.setProperty(SEC_TYPE_PROPERTY, secType);
    node.visitChildren(this);
    return true;
  }

  @override
  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    var secType = _getConstructorSecType(node);
    node.setProperty(SEC_TYPE_PROPERTY, secType);

    super.visitConstructorDeclaration(node);
    return true;
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    node.visitChildren(this);
    if (isDeclassifyOperator(node.function)) {
      assert(node.argumentList.arguments.length == 2);
      final secondArgument = node.argumentList.arguments[1];
      if (secondArgument is SimpleStringLiteral) {
        var label = _elementParser.parseLiteralLabel(
            secondArgument, secondArgument.value);

        secondArgument.setProperty(SEC_LABEL_PROPERTY, label);
        return true;
      }
      _reporter
          .onError(SecurityTypeError.getInvalidDeclassifyCall(secondArgument));
    }
    return true;
  }

  @override
  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    var secType = new DynamicSecurityType(_elementParser.lattice.dynamic);
    if (!_checkSimpleLabelAnnotation(node)) {
      return false;
    }
    secType = _elementParser.fromIdentifierDeclaration(
        node.element, node.element.type);
    node.setProperty(SEC_TYPE_PROPERTY, secType);
    return true;
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    var secType = null;
    if (node.parent is FunctionDeclaration &&
        node.parent.getProperty(SEC_TYPE_PROPERTY) != null) {
      secType = node.getProperty(SEC_TYPE_PROPERTY);
    } else {
      secType = _elementParser.getFunctionSecType(
          node.element.metadata
              .map((m) => (m as ElementAnnotationImpl).annotationAst),
          node.element.parameters,
          node.element.returnType);
    }

    node.setProperty(SEC_TYPE_PROPERTY, secType);

    super.visitFunctionExpression(node);
    return true;
  }

  @override
  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    var secType = _elementParser.fromIdentifierDeclaration(
        node.element, node.element.type);
    node.setProperty(SEC_TYPE_PROPERTY, secType);
    return true;
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    for (VariableDeclaration variable in node.variables) {
      var secType = new DynamicSecurityType(_elementParser.lattice.dynamic);
      if (_checkSimpleLabelAnnotation(node)) {
        secType = _elementParser.fromIdentifierDeclaration(
            variable.element, variable.element.type);
      }
      variable.setProperty(SEC_TYPE_PROPERTY, secType);
    }
    node.visitChildren(this);
    return true;
  }

  DartType getDartTypeFromParameter(FormalParameter parameter) {
    if (astIsResolved) return parameter.element.type;
    return DynamicTypeImpl.instance;
  }

  DartType getFunctionDartReturnType(dynamic node) {
    if (astIsResolved) return node.element.returnType;
    return DynamicTypeImpl.instance;
  }

  DartType getDartTypeFromVariable(VariableDeclaration node) {
    if (astIsResolved) return node.element.type;
    return DynamicTypeImpl.instance;
  }

  SecurityFunctionType _getFunctionSecType(FunctionDeclaration node) {
    return _getExecutableNodeSecType(
        node, node.functionExpression.parameters, node.metadata, node.element);
  }

  SecurityFunctionType _getMethodSecType(MethodDeclaration node) {
    return _getExecutableNodeSecType(
        node, node.parameters, node.metadata, node.element);
  }

  SecurityFunctionType _getConstructorSecType(ConstructorDeclaration node) {
    return _getExecutableNodeSecType(
        node, node.parameters, node.metadata, node.element);
  }

  SecurityFunctionType _getExecutableNodeSecType(
      AstNode node,
      FormalParameterList parameters,
      NodeList<Annotation> metadata,
      ExecutableElement element) {
    if (!_checkFunctionSecurityAnnotations(node, parameters)) {
      return null;
    }
    return _elementParser.getFunctionSecType(
        metadata, element.parameters, element.returnType);
  }

  /**
   * Get the security annotation for a formal parameter.
   */
  bool _checkSimpleLabelAnnotation(dynamic parameter) {
    var secLabelAnnotations =
        parameter.metadata.where((x) => _parser.isLabel(x));
    if (secLabelAnnotations.length > 1) {
      _reporter.onError(
          SecurityTypeError.getDuplicatedLabelOnParameterError(parameter));
      return false;
    } else if (secLabelAnnotations.length == 1) {
      return _parser.isLabel(secLabelAnnotations.first);
    }
    return true;
  }

  bool _checkFunctionSecurityAnnotations(
      dynamic node, FormalParameterList parameters) {
    if (!(node is FunctionDeclaration) &&
        !(node is MethodDeclaration) &&
        !(node is FunctionTypedFormalParameter) &&
        !(node is ConstructorDeclaration)) {
      _reporter.onError(SecurityTypeError.getImplementationError(
          node,
          "I do "
          "not recognize this node. [Method:_checkFunctionSecurityAnnotations]"));
      return false;
    }
    var metadataList = node.metadata;

    if (metadataList != null) {
      var latentAnnotations =
          metadataList.where((a) => a.name.name == FUNCTION_LATENT_LABEL);

      if (latentAnnotations.length > 1) {
        _reporter.onError(SecurityTypeError.getDuplicatedLatentError(node));
        return false;
      }
      var returnAnnotations = metadataList.where((a) => _parser.isLabel(a));
      if (returnAnnotations.length > 1) {
        _reporter.onError(SecurityTypeError.getDuplicatedLatentError(node));
        return false;
      }
      if (returnAnnotations.length == 1) {
        return _parser.isLabel(returnAnnotations.first);
      }
    }
    return true;
  }
}
