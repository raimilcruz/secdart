import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/analyzer.dart';
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

  isLabel(Annotation a);

  SecurityLabel parseString(String value);
}

/**
 * Parses a lattice with four element: BOT < LOW < HIGH < TOP and the
 * dynamic label (dyn)
 */
class FlatLatticeParser extends SecAnnotationParser {
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

  FlatLatticeParser(AnalysisErrorListener this.errorListener,
      [bool intervalMode = false]) {
    this.intervalMode = intervalMode;
  }

  @override
  FunctionAnnotationLabel parseFunctionLabel(Annotation n) {
    // TODO: Report error in a proper way
    if (n.name.name != FUNCTION_LATENT_LABEL) {
      errorListener
          .onError(SecurityTypeError.getDuplicatedLabelOnParameterError(n));
      throw new Exception();
    }
    var arguments = n.arguments.arguments;
    if (arguments.length != 2) {
      errorListener.onError(SecurityTypeError.getBadFunctionLabel(n));
      throw new Error();
    }
    var beginLabelString = arguments[0] as SimpleStringLiteral;
    var endLabelString = arguments[1] as SimpleStringLiteral;

    var beginLabel = _parseLiteralLabel(beginLabelString.stringValue);
    var endLabel = _parseLiteralLabel(endLabelString.stringValue);
    return new FunctionAnnotationLabel(beginLabel, endLabel);
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
        return this.lattice.dynamic;
      default:
        throw new SecCompilationException(
            "Annotation does not represent a label for me!");
    }
  }

  SecurityLabel _parseLiteralLabel(String label) {
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
        return this.lattice.dynamic;
      default:
        throw new SecCompilationException(
            "String does not represent a label for me!");
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
  SecurityLabel parseString(String value) {
    return _parseLiteralLabel(value);
  }
}

/**
 * Represents the security labels associated to a function.
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
  final String message;
  SecCompilationException([this.message]);

  @override
  String getMessage() => message;
}
