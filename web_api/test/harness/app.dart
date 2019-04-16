import 'package:aqueduct/src/db/managed/context.dart';
import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:secdart_analyzer/analyzer.dart';
import 'package:web_api/service/analyzer_service.dart';
import 'package:web_api/web_api.dart';

export 'package:aqueduct_test/aqueduct_test.dart';
export 'package:test/test.dart';
export 'package:aqueduct/aqueduct.dart';

class FakeAnalyzerService extends IAnalyzerService {
  @override
  SecAnalysisResult analyze(String program, [bool useInterval = false]) {
    return new SecAnalysisResult(new List(), null);
  }
}

class FakeCompilerService extends ICompilerService {
  @override
  String compile(String source, {bool format = false}) {
    return "fake compilation";
  }
}

class FakeWebApi extends WebApi {
  @override
  Future prepare() async {
    secAnalyzer = new FakeAnalyzerService();
    secCompiler = new FakeCompilerService();
  }
}

class Harness extends TestHarness<FakeWebApi> {
  @override
  Future onSetUp() async {
    //await resetData();
  }
}
