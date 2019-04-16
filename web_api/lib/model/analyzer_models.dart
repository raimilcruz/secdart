import 'package:analyzer/error/error.dart';
import 'package:aqueduct/aqueduct.dart';

class StringWrapper {
  String result;
  StringWrapper();
}

class SecAnalysisResultModel implements Serializable {
  List<SecIssue> issues;
  SecAnalysisResultModel();

  @override
  Map<String, dynamic> asMap() {
    return {"issues": issues.map((i) => i.asMap()).toList()};
  }

  @override
  APISchemaObject documentSchema(APIDocumentContext context) {
    // TODO: implement documentSchema
    return null;
  }

  @override
  void read(Map<String, dynamic> object,
      {Iterable<String> ignore,
      Iterable<String> reject,
      Iterable<String> require}) {
    // TODO: implement read
  }

  @override
  void readFromMap(Map<String, dynamic> object) {
    // TODO: implement readFromMap
  }
}

class SecCompileResult implements Serializable {
  String compiled;

  @override
  Map<String, dynamic> asMap() {
    return {"compiled": compiled};
  }

  @override
  APISchemaObject documentSchema(APIDocumentContext context) {
    // TODO: implement documentSchema
    return null;
  }

  @override
  void read(Map<String, dynamic> object,
      {Iterable<String> ignore,
      Iterable<String> reject,
      Iterable<String> require}) {
    // TODO: implement read
  }

  @override
  void readFromMap(Map<String, dynamic> object) {
    // TODO: implement readFromMap
  }
}

class SecIssue extends Serializable {
  String kind;
  String message;
  int line;
  int charStart;
  int charLength;
  int column;

  @override
  Map<String, dynamic> asMap() {
    return {
      "kind": kind,
      "message": message,
      "line": line,
      "charStart": charStart,
      "charLength": charLength,
      "column": column
    };
  }

  @override
  void readFromMap(Map<String, dynamic> object) {
    // TODO: implement readFromMap
  }
}

class SecAnalysisInput extends Serializable {
  String source;
  bool useInterval;

  @override
  Map<String, dynamic> asMap() {
    // TODO: implement asMap
    return null;
  }

  @override
  void readFromMap(Map<String, dynamic> map) {
    source = map['source'] as String;
    useInterval = map['useInterval'] as bool;
  }
}

class AnalyzerErrorMapper {
  //helper method
  static SecIssue mapToModel(AnalysisError error) {
    var issue = new SecIssue();
    issue.message = error.message;
    issue.kind = "secerror";
    issue.charLength = error.length;
    issue.charStart = error.offset;

    //TODO: compute line and column.
    issue.column = 0;
    issue.line = 0;
    return issue;
  }
}
