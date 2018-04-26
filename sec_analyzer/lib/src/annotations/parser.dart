import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:secdart_analyzer/security_label.dart';
import '../errors.dart';

const String FUNCTION_LATENT_LABEL = "latent";

/**
 * An abstract parser for Dart annotations that represent security labels
 */
abstract class SecAnnotationParser {
  /**
   * Parsers a [SecurityLabel] from an annotation
   */
  LabelNode parseLabel(Annotation n);

  /**
   * Parses function labels from an annotation
   */
  FunctionAnnotationLabel parseFunctionLabel(Annotation n);

  /**
   * This method must assume that there is no error in list of annotations
   * (eg. repeated function latent error o non-recognizable labels)
   */
  FunctionLevelLabels getFunctionLevelLabels(List<Annotation> metadata);

  isLabel(Annotation a);

  LabelNode parseString(AstNode nodeToReportError, String value);
}

abstract class BaseLatticeParser extends SecAnnotationParser {
  AnalysisErrorListener errorListener;
  CompilationUnit unit;

  BaseLatticeParser(
      AnalysisErrorListener this.errorListener, CompilationUnit this.unit) {}

  @override
  FunctionLevelLabels getFunctionLevelLabels(List<Annotation> metadata) {
    var beginLabel = LabelNode.noAnnotated;
    var endLabel = LabelNode.noAnnotated;
    ;
    var returnLabel = LabelNode.noAnnotated;
    ;
    if (metadata != null) {
      var latentAnnotations =
          metadata.where((a) => a.name.name == FUNCTION_LATENT_LABEL);

      if (latentAnnotations.length == 1) {
        Annotation securityFunctionAnnotation = latentAnnotations.first;
        var funAnnotationLabel = parseFunctionLabel(securityFunctionAnnotation);
        beginLabel = funAnnotationLabel.beginLabel;
        endLabel = funAnnotationLabel.endLabel;
      }

      var returnAnnotations = metadata.where((a) => isLabel(a));
      if (returnAnnotations.length == 1) {
        returnLabel = parseLabel(returnAnnotations.first);
      }
    }
    return new FunctionLevelLabels(
        returnLabel, new FunctionAnnotationLabel(beginLabel, endLabel));
  }

  @override
  FunctionAnnotationLabel parseFunctionLabel(Annotation n) {
    if (n.name.name != FUNCTION_LATENT_LABEL) {
      errorListener.onError(SecurityTypeError.getNotRecognizedFunctionLabel(n));
      throw new Exception();
    }
    var arguments = n.arguments.arguments;
    if (arguments.length != 2) {
      errorListener.onError(SecurityTypeError.getBadFunctionLabel(n));
      throw new Error();
    }
    var beginLabelString = arguments[0] as SimpleStringLiteral;
    var endLabelString = arguments[1] as SimpleStringLiteral;

    var beginLabel =
        parseString(beginLabelString, beginLabelString.stringValue);
    var endLabel = parseString(endLabelString, endLabelString.stringValue);
    return new FunctionAnnotationLabel(beginLabel, endLabel);
  }
}

/**
 * Parses a lattice with four element: BOT < LOW < HIGH < TOP and the
 * dynamic label (dyn) from annotations: @low, @bot, @high, @top, @dyn.
 */
class FourLatticeParser extends BaseLatticeParser {
  Map<String, String> _literalLabelMap = {
    "H": "H",
    "L": "L",
    "bot": "bot",
    "top": "top",
    "?": "?"
  };
  Map<String, String> annotationLabelMap = {
    "high": "H",
    "low": "L",
    "bot": "bot",
    "top": "top",
    "dynl": "?"
  };

  /**
   * Creates a [FourLatticeParser] instance
   */
  FourLatticeParser(AnalysisErrorListener errorListener, CompilationUnit unit)
      : super(errorListener, unit) {}

  @override
  LabelNode parseLabel(Annotation n) {
    if (!isLabel(n)) {
      errorListener.onError(SecurityTypeError.getInvalidLabel(n));
      return new LabelNodeImpl(LatticeConfig.defaultLattice.unknown);
    }
    return new LabelNodeImpl(annotationLabelMap[n.name.name]);
  }

  LabelNode _parseLiteralLabel(AstNode node, String label) {
    if (_literalLabelMap.containsKey(label)) {
      return new LabelNodeImpl(_literalLabelMap[label]);
    } else {
      errorListener.onError(SecurityTypeError.getInvalidLabel(node));
      return new LabelNodeImpl(LatticeConfig.defaultLattice.unknown);
    }
  }

  @override
  isLabel(Annotation a) {
    return (annotationLabelMap.containsKey(a.name.name));
  }

  @override
  LabelNode parseString(AstNode nodeToReportError, String value) {
    return _parseLiteralLabel(nodeToReportError, value);
  }
}

class ConfigurableLatticeParser extends BaseLatticeParser {
  static String labelAnnotationName = "lab";
  List<String> recognizedLabels;
  LatticeConfig latticeConfig;

  ConfigurableLatticeParser(LatticeConfig latticeConfig,
      AnalysisErrorListener errorListener, CompilationUnit unit)
      : super(errorListener, unit) {
    recognizedLabels = latticeConfig.elements;
  }

  @override
  isLabel(Annotation a) {
    return a.name.name == labelAnnotationName &&
        a.arguments.arguments.length == 1 &&
        a.arguments.arguments.first is SimpleStringLiteral &&
        recognizedLabels.contains(
            (a.arguments.arguments.first as SimpleStringLiteral).value);
  }

  @override
  LabelNode parseLabel(Annotation n) {
    if (!isLabel(n)) {
      throw new ArgumentError(
          "The method 'parseLabel' expect an already validated "
          "annotation. Use the method 'isLabel' before to call 'parseLabel'");
    }
    final stringLabel = n.arguments.arguments.first as SimpleStringLiteral;
    if (stringLabel != null) {
      if (recognizedLabels.contains(stringLabel.value)) {
        return new LabelNodeImpl(stringLabel.value);
      }
    }
    errorListener.onError(SecurityTypeError.getInvalidLabel(n));
    return LabelNode.noAnnotated;
  }

  @override
  LabelNode parseString(AstNode nodeToReportError, String value) {
    if (recognizedLabels.contains(value)) {
      return new LabelNodeImpl(value);
    }
    errorListener.onError(SecurityTypeError.getInvalidLabel(nodeToReportError));
    return LabelNode.noAnnotated;
  }
}

abstract class AnnotatedLabel {}

class SimpleAnnotatedLabel extends AnnotatedLabel {
  LabelNode label;

  SimpleAnnotatedLabel(this.label);
}

class FunctionLevelLabels extends AnnotatedLabel {
  LabelNode returnLabel;
  FunctionAnnotationLabel functionLabels;

  FunctionLevelLabels(this.returnLabel, this.functionLabels);
}

/**
 * Contains the security labels annotated to a function.
 */
class FunctionAnnotationLabel {
  /**
   * We use the same name than in JIF to name the label that is an upper bound
   * of the caller context pc.
   */
  LabelNode beginLabel;

  /**
   *
   */
  LabelNode endLabel;

  FunctionAnnotationLabel(LabelNode this.beginLabel, LabelNode this.endLabel);
}

class LabelNodeImpl extends LabelNode {
  static Map<String, LabelNodeImpl> _cache = {};
  String _rep;

  factory LabelNodeImpl(String representation) {
    if (!_cache.containsKey(representation)) {
      _cache[representation] = new LabelNodeImpl._(representation);
    }
    return _cache[representation];
  }

  LabelNodeImpl._(this._rep);

  @override
  String get literalRepresentation => _rep;

  @override
  String toString() => literalRepresentation;

  @override
  bool operator ==(other) {
    if (other is LabelNodeImpl) {
      return other.literalRepresentation == literalRepresentation;
    }
    return false;
  }

  @override
  int get hashCode => literalRepresentation.hashCode;
}

class SecCompilationException implements SecDartException {
  AstNode node;
  final String message;

  SecCompilationException(AstNode this.node, [this.message]);

  @override
  String getMessage() => message;
}

///The result of the security parser. A map from [Element]s to [AnnotatedLabel].
class LabelMap {
  final Map<Element, AnnotatedLabel> map = {};
}
