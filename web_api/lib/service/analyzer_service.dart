import 'package:secdart_analyzer/analyzer.dart';
import 'package:security_transformer/security_compiler.dart';

abstract class IAnalyzerService {
  SecAnalysisResult analyze(String program, [bool useInterval = false]);
}

abstract class ICompilerService {
  String compile(String source, {bool format: false});
}

class AnalyzerService implements IAnalyzerService {
  @override
  SecAnalysisResult analyze(String program, [bool useInterval = false]) {
    var analyzer = new SecAnalyzer();
    return analyzer.analyze(program, useInterval);
  }
}

class CompilerService implements ICompilerService {
  @override
  String compile(String source, {bool format = false}) {
    var compiler = new SecurityCompiler();
    return compiler.compile(source, format: format);
  }
}
