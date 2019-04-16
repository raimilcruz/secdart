import 'package:aqueduct/aqueduct.dart';
import 'package:secdart_analyzer/analyzer.dart';
import 'package:security_transformer/security_compiler.dart';
import 'package:web_api/model/analyzer_models.dart';
import 'package:web_api/service/analyzer_service.dart';

/**
 * A simple REST API for the security analysis. This is not intented to use
 * for other project, except for the SecDart Pad.
 */
class CompilerController extends ResourceController {
  ICompilerService secCompiler;
  CompilerController(this.secCompiler);

  @Operation.post()
  Future<Response> compile(@Bind.body() SecAnalysisInput input) async {
    var compiled = secCompiler.compile(input.source, format: true);
    return new Response.ok(new SecCompileResult()..compiled = compiled);
  }
}
