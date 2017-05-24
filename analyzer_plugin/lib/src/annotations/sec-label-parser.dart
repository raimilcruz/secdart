import '../security_label.dart';
import 'package:analyzer/dart/ast/ast.dart';

/**
 * An abstract parser for Dart annotations that represent security labels
 */
abstract class SecAnnotationParser{
  /**
   * When is implemented returns the dynamic label
   */
  get dynamicLabel;

  SecurityLabel parseLabel(Annotation n);
  dynamic parseFunctionLabel(Annotation n);

  isLabel(Annotation a);
}

class FlatLatticeParser extends SecAnnotationParser{
  static const String FUNCTION_LATENT_LABEL = "latent";

  @override
  parseFunctionLabel(Annotation n) {
    // TODO: Report error in a proper way
    if(n.name.name != FUNCTION_LATENT_LABEL){
      throw new ArgumentError("Annotation does not represent a function label");
    }
    var arguments = n.arguments.arguments;
    if(arguments.length!=2){
      throw new ArgumentError("latent annotation must have 2 parameters");
    }
    var beginLabelString = arguments[0] as SimpleStringLiteral;
    var endLabelString = arguments[1] as SimpleStringLiteral;

    var list = new List();
    list.add(_parseFunctionLabelArgument(beginLabelString.stringValue));
    list.add(_parseFunctionLabelArgument(endLabelString.stringValue));
    return list;
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
        return new DynamicLabel();
      default:
        throw new ArgumentError(
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
        return new DynamicLabel();
      default:
        throw new ArgumentError("String does not represent a label for me!");
    }
  }

  @override
  get dynamicLabel {
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