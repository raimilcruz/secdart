import 'package:secdart_analyzer/src/annotations/parser.dart';

///Configuration options for the analysis, for extensions to the analysis.
///eg. to support a different lattice.
class SecDartConfig {
  static final SecDartConfig instance = new SecDartConfig._();

  factory SecDartConfig() => instance;

  SecDartConfig._();
  SecAnnotationParser parser;
}
