import 'package:aqueduct/aqueduct.dart';
import 'package:secdart_analyzer/analyzer.dart';
import 'package:security_transformer/security_compiler.dart';
import 'package:web_api/model/analyzer_models.dart';
import 'package:web_api/service/analyzer_service.dart';

/**
 * A simple REST API for the security analysis. This is not intented to use
 * for other project, except for the SecDart Pad.
 */
class AnalyzerController extends ResourceController {
  IAnalyzerService secAnalyzer;
  AnalyzerController(this.secAnalyzer);

  @Operation.get()
  Future<Response> list() async {
    return new Response.ok(["A", "B", "C"]);
  }

  @Operation.post()
  Future<Response> analyze(@Bind.body() SecAnalysisInput input) async {
    var errors = secAnalyzer.analyze(input.source, input.useInterval).errors;

    SecAnalysisResultModel result = new SecAnalysisResultModel()
      ..issues = errors.map(AnalyzerErrorMapper.mapToModel).toList();
    return new Response.ok(result);
  }

  /*@override
  Future handleError(Request request, dynamic caughtValue, StackTrace trace) async {
    print("Exception value: " + caughtValue);
    print("Stacke trace:" + trace.toString());
    await super.handleError(request, caughtValue, trace);
  }
  */

}
