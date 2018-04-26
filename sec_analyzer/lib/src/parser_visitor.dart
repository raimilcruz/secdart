import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/errors.dart';
import 'package:secdart_analyzer/src/helper.dart';

/**
    It parses security elements, that is annotations of security labels
    We do not need to manage scope since we do not change Dart scope,
    We just need to re-process the AST to include security
    annotations.
 */
class SecurityParserVisitor extends GeneralizingAstVisitor<bool> {
  AnalysisErrorListener _reporter;
  LabelMap _labelMap;

  /**
   * The parser used to get label from annotation
   */
  SecAnnotationParser _parser;

  final bool astIsResolved;

  SecurityParserVisitor(AnalysisErrorListener reporter, CompilationUnit unit,
      SecAnnotationParser parser,
      [this.astIsResolved = true]) {
    _reporter = reporter;
    _parser = parser;
    _labelMap = new LabelMap();
  }

  LabelMap get labeMap => _labelMap;

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
    var label = _checkSimpleLabelAnnotation(node);
    node.setProperty(SEC_LABEL_PROPERTY, label);
    node.fields.variables.forEach((vd) {
      vd.setProperty(SEC_LABEL_PROPERTY, label);
      _labelMap.map
          .putIfAbsent(vd.element, () => new SimpleAnnotatedLabel(label));
    });
    _labelMap.map
        .putIfAbsent(node.element, () => new SimpleAnnotatedLabel(label));

    node.visitChildren(this);
    return true;
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    final functionLabelResult = _getFunctionSecurityAnnotations(node);

    setFunctionLabels(functionLabelResult, node, node.element);

    super.visitMethodDeclaration(node);
    return true;
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    final functionLabelResult = _getFunctionSecurityAnnotations(node);

    setFunctionLabels(functionLabelResult, node, node.element);

    node.visitChildren(this);
    return true;
  }

  void setFunctionLabels(
      _FunctionLabelResult functionLabelResult, AstNode node, Element element) {
    FunctionLevelLabels labels = new FunctionLevelLabels(
        new NoAnnotatedLabel(),
        new FunctionAnnotationLabel(
            new NoAnnotatedLabel(), new NoAnnotatedLabel()));
    if (!functionLabelResult.errorOnLabel) {
      if (functionLabelResult.returnLabel != null) {
        labels.returnLabel = functionLabelResult.returnLabel.label;
      }
      if (functionLabelResult.functionLabel != null) {
        labels.functionLabels = functionLabelResult.functionLabel;
      }
    }
    node.setProperty(SEC_LABEL_PROPERTY, labels);
    _labelMap.map.putIfAbsent(element, () => labels);
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    node.visitChildren(this);
    if (isDeclassifyOperator(node.function)) {
      assert(node.argumentList.arguments.length == 2);
      final secondArgument = node.argumentList.arguments[1];
      if (secondArgument is SimpleStringLiteral) {
        var label = _parser.parseString(secondArgument, secondArgument.value);

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
    var annotatedLabel = _checkSimpleLabelAnnotation(node);
    setSimpleLabel(annotatedLabel, node, node.element);

    return true;
  }

  void setSimpleLabel(LabelNode annotatedLabel, AstNode node, Element element) {
    var label = new NoAnnotatedLabel();

    if (annotatedLabel != null) {
      label = annotatedLabel;
    }
    node.setProperty(SEC_LABEL_PROPERTY, new SimpleAnnotatedLabel(label));
    if (element != null) {
      _labelMap.map.putIfAbsent(element, () => new SimpleAnnotatedLabel(label));
    }
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration &&
        node.parent.getProperty(SEC_LABEL_PROPERTY) != null) {
      final secLabel = node.parent.getProperty(SEC_LABEL_PROPERTY);
      node.setProperty(SEC_LABEL_PROPERTY, secLabel);
      _labelMap.map.putIfAbsent(node.element, () => secLabel);
    } else {
      //In this case the FunctionExpression node represents a lambda and
      //it is not possible to annotate lambda (or any value).
      final functionLabelResult = new _FunctionLabelResult.fromLabels(
          new FunctionAnnotationLabel(
              new NoAnnotatedLabel(), new NoAnnotatedLabel()),
          new SimpleAnnotatedLabel(new NoAnnotatedLabel()));

      setFunctionLabels(functionLabelResult, node, node.element);
    }

    node.visitChildren(this);
    return true;
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    LabelNode annotatedLabel;
    //global variable declaration
    if (node.parent is TopLevelVariableDeclaration) {
      annotatedLabel = _checkSimpleLabelAnnotation(node.parent);
    }
    //local variable declaration
    else {
      annotatedLabel = _checkSimpleLabelAnnotation(node);
    }
    for (VariableDeclaration variable in node.variables) {
      setSimpleLabel(annotatedLabel, node, variable.element);
    }
    node.visitChildren(this);
    return true;
  }

  DartType getFunctionDartReturnType(dynamic node) {
    if (astIsResolved) return node.element.returnType;
    return DynamicTypeImpl.instance;
  }

  /**
   * Get the security annotation for a formal parameter.
   */
  LabelNode _checkSimpleLabelAnnotation(dynamic parameter) {
    var secLabelAnnotations =
        parameter.metadata.where((x) => _parser.isLabel(x));
    if (secLabelAnnotations.length > 1) {
      _reporter.onError(
          SecurityTypeError.getDuplicatedLabelOnParameterError(parameter));
      return null;
    } else if (secLabelAnnotations.length == 1) {
      return _parser.parseLabel(secLabelAnnotations.first);
    }
    return null;
  }

  _FunctionLabelResult _getFunctionSecurityAnnotations(dynamic node) {
    if (!(node is FunctionDeclaration) &&
        !(node is MethodDeclaration) &&
        !(node is FunctionTypedFormalParameter)) {
      _reporter.onError(SecurityTypeError.getImplementationError(
          node,
          "I do "
          "not recognize this node. [Method:_checkFunctionSecurityAnnotations]"));
      return new _FunctionLabelResult.fromError();
    }
    var metadataList = node.metadata;

    FunctionAnnotationLabel functionLabel;
    SimpleAnnotatedLabel returnLabel;

    if (metadataList != null) {
      var latentAnnotations =
          metadataList.where((a) => a.name.name == FUNCTION_LATENT_LABEL);

      if (latentAnnotations.length > 1) {
        _reporter.onError(SecurityTypeError.getDuplicatedLatentError(node));
        return new _FunctionLabelResult.fromError();
      }
      if (latentAnnotations.length == 1) {
        functionLabel = _parser.parseFunctionLabel(latentAnnotations.first);
      }
      var returnAnnotations = metadataList.where((a) => _parser.isLabel(a));
      if (returnAnnotations.length > 1) {
        _reporter
            .onError(SecurityTypeError.getDuplicatedReturnLabelError(node));
        return new _FunctionLabelResult.fromError();
      }
      if (returnAnnotations.length == 1) {
        returnLabel = new SimpleAnnotatedLabel(
            _parser.parseLabel(returnAnnotations.first));
      }
    }
    return new _FunctionLabelResult.fromLabels(functionLabel, returnLabel);
  }
}

class _FunctionLabelResult {
  bool errorOnLabel;
  FunctionAnnotationLabel functionLabel;
  SimpleAnnotatedLabel returnLabel;

  _FunctionLabelResult.fromError() {
    errorOnLabel = true;
  }

  _FunctionLabelResult.fromLabels(this.functionLabel, this.returnLabel) {
    errorOnLabel = false;
  }
}
