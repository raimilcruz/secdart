import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:secdart_analyzer/security_label.dart';
import '../security_label.dart';
import '../errors.dart';

const String FUNCTION_LATENT_LABEL = "latent";

/**
 * An abstract parser for Dart annotations that represent security labels
 */
abstract class SecAnnotationParser {
  /**
   * A general representation of the lattice this parser parses
   */
  Lattice get lattice;

  /**
   * Parsers a [SecurityLabel] from an annotation
   */
  SecurityLabel parseLabel(Annotation n);

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

  SecurityLabel parseString(AstNode nodeToReportError, String value);
}

/**
 * Parses a lattice with four element: BOT < LOW < HIGH < TOP and the
 * dynamic label (dyn)
 */
class FourLatticeParser extends SecAnnotationParser {
  AnalysisErrorListener errorListener;
  bool intervalMode;
  Lattice _lattice;

  @override
  Lattice get lattice {
    if (_lattice == null) {
      _lattice = intervalMode ? new IntervalFlatLattice() : new FlatLattice();
    }
    return _lattice;
  }

  /**
   * Creates a [FourLatticeParser] instance
   */
  FourLatticeParser(
      AnalysisErrorListener this.errorListener, CompilationUnit unit,
      [bool intervalMode = false]) {
    this.intervalMode = intervalMode;
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
        _parseLiteralLabel(beginLabelString, beginLabelString.stringValue);
    var endLabel =
        _parseLiteralLabel(endLabelString, endLabelString.stringValue);
    return new FunctionAnnotationLabel(beginLabel, endLabel);
  }

  @override
  SecurityLabel parseLabel(Annotation n) {
    var annotationName = n.name.name;
    switch (annotationName) {
      case 'high':
        return _liftLabelToIntervalIfNeeded(new HighLabel());
      case 'low':
        return _liftLabelToIntervalIfNeeded(new LowLabel());
      case 'top':
        return _liftLabelToIntervalIfNeeded(new TopLabel());
      case 'bot':
        return _liftLabelToIntervalIfNeeded(new BotLabel());
      case 'dynl':
        return this.lattice.dynamic;
      default:
        errorListener.onError(SecurityTypeError.getInvalidLabel(n));
        return this.lattice.dynamic;
    }
  }

  SecurityLabel _parseLiteralLabel(AstNode node, String label) {
    switch (label) {
      case 'H':
        return _liftLabelToIntervalIfNeeded(new HighLabel());
      case 'L':
        return _liftLabelToIntervalIfNeeded(new LowLabel());
      case 'top':
        return _liftLabelToIntervalIfNeeded(new TopLabel());
      case 'bot':
        return _liftLabelToIntervalIfNeeded(new BotLabel());
      case 'dynl':
        return this.lattice.dynamic;
      default:
        errorListener
            .onError(SecurityTypeError.getInvalidLiteralLabel(node, label));
        return this.lattice.dynamic;
    }
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

  @override
  SecurityLabel parseString(AstNode nodeToReportError, String value) {
    return _parseLiteralLabel(nodeToReportError, value);
  }

  @override
  FunctionLevelLabels getFunctionLevelLabels(List<Annotation> metadata) {
    var beginLabel = lattice.dynamic;
    var endLabel = lattice.dynamic;
    var returnLabel = lattice.dynamic;
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

  SecurityLabel _liftLabelToIntervalIfNeeded(SecurityLabel label) {
    return intervalMode
        ? (!(label is UnknownLabel)
            ? new IntervalLabel(label, label)
            : lattice.dynamic)
        : label;
  }
}

abstract class AnnotatedLabel {}

class SimpleAnnotatedLabel extends AnnotatedLabel {
  SecurityLabel label;

  SimpleAnnotatedLabel(this.label);
}

class FunctionLevelLabels extends AnnotatedLabel {
  SecurityLabel returnLabel;
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
  SecurityLabel beginLabel;

  /**
   *
   */
  SecurityLabel endLabel;

  FunctionAnnotationLabel(
      SecurityLabel this.beginLabel, SecurityLabel this.endLabel);
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
