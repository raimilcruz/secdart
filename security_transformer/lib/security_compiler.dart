import 'package:dart_style/src/dart_formatter.dart';
import 'package:secdart_analyzer/analyzer.dart';
import 'package:security_transformer/src/replacer_visitor.dart';

/**
 * A compiler from SecDart to Dart.
 */
class SecurityCompiler {
  static final _replacerVisitor = new ReplacerVisitor();
  DartFormatter formatter = new DartFormatter();

  /**
   * Given a source (of SecDart) generates the compiled version with security
   * checks.
   */
  String compile(String source, {bool format: false}) {
    final secAnalyzer = new SecAnalyzer();
    ;
    final result = secAnalyzer.analyze(source);
    final compilationUnit = result.astNode;

    compilationUnit.accept(_replacerVisitor);
    final compiled =
        "import 'package:security_transformer/src/security_value.dart'; " +
            compilationUnit.toString();
    if (format) return formatter.format(compiled);
    return compiled;
  }
}
