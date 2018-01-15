import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import '../security_label.dart';
import '../security_type.dart';
import '../errors.dart';

const String FUNCTION_LATENT_LABEL = "latent";

/**
 * An abstract parser for Dart annotations that represent security labels
 */
abstract class SecAnnotationParser {
  /**
   * When is implemented returns the dynamic label
   */
  get dynamicLabel;

  SecurityLabel parseLabel(Annotation n);
  FunctionAnnotationLabel parseFunctionLabel(Annotation n);

  isLabel(Annotation a);
}

abstract class SecAnnotationParser2 {
  SecurityFunctionType getFunctionSecType(FunctionDeclaration node);
}

class FlatLatticeParser extends SecAnnotationParser {
  AnalysisErrorListener errorListener;
  bool intervalMode;

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

    var beginLabel = _parseFunctionLabelArgument(beginLabelString.stringValue);
    var endLabel = _parseFunctionLabelArgument(endLabelString.stringValue);
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
        throw new SecCompilationException(
            "String does not represent a label for me!");
    }
  }

  @override
  get dynamicLabel {
    if (intervalMode) return new IntervalLabel(new BotLabel(), new TopLabel());
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

class FunctionAnnotationLabel {
  SecurityLabel beginLabel;
  SecurityLabel endLabel;
  FunctionAnnotationLabel(
      SecurityLabel this.beginLabel, SecurityLabel this.endLabel);

  SecurityLabel getBeginLabel() => beginLabel;
  SecurityLabel getEndLabel() => endLabel;
}

class SecCompilationException implements SecDartException {
  final String message;
  SecCompilationException([this.message]);

  @override
  String getMessage() => message;
}

abstract class SecElementAnnotationParser {
  /**
   * When is implemented returns the dynamic label
   */
  get dynamicLabel;

  SecurityLabel parseLabel(ElementAnnotation n);
  FunctionAnnotationLabel parseFunctionLabel(ElementAnnotation n);

  isLabel(ElementAnnotation a);
}

class FlatLatticeElementParser extends SecElementAnnotationParser {
  FlatLatticeParser _parser;
  bool intervalMode;

  FlatLatticeElementParser([bool intervalMode = false]) {
    this.intervalMode = intervalMode;
    _parser = new FlatLatticeParser(new ErrorCollector(), intervalMode);
  }

  @override
  SecurityLabel parseLabel(ElementAnnotation n) {
    ElementAnnotationImpl elementAnnotationImpl = n;
    var annotationAst = elementAnnotationImpl.annotationAst;
    return _parser.parseLabel(annotationAst);
  }

  FunctionAnnotationLabel parseFunctionLabel(ElementAnnotation n) {
    ElementAnnotationImpl elementAnnotationImpl = n;
    var annotationAst = elementAnnotationImpl.annotationAst;
    return _parser.parseFunctionLabel(annotationAst);
  }

  @override
  get dynamicLabel {
    if (intervalMode) return new IntervalLabel(new BotLabel(), new TopLabel());
    return new DynamicLabel();
  }

  @override
  isLabel(ElementAnnotation a) {
    ElementAnnotationImpl elementAnnotationImpl = a;
    var annotationAst = elementAnnotationImpl.annotationAst;
    return _parser.isLabel(annotationAst);
  }
}
