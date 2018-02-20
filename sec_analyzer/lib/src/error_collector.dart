import 'package:analyzer/analyzer.dart';

class ErrorCollector extends AnalysisErrorListener {
  List<AnalysisError> errors;
  ErrorCollector() {
    errors = new List<AnalysisError>();
  }
  @override
  onError(error) => errors.add(error);
}
