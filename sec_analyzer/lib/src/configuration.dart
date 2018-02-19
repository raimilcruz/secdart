import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/annotations/parser_element.dart';

class SecDartConfig {
  static final SecDartConfig instance = new SecDartConfig._();

  factory SecDartConfig() => instance;

  SecDartConfig._();

  SecAnnotationParser parser;
  ElementAnnotationParser elementParser;
}
