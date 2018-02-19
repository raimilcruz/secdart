import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/dart.dart';
import 'package:secdart_analyzer/src/context.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/experimental/task.dart';
import 'package:secdart_analyzer/src/gs_typesystem.dart';
import 'package:secdart_analyzer/src/parser_visitor.dart';
import 'package:secdart_analyzer/src/security_resolver.dart';
import 'package:secdart_analyzer/src/security_visitor.dart'
    show SecurityCheckerVisitor;
import 'package:analyzer/analyzer.dart' show AnalysisError, CompilationUnit;
import 'dart:io' as io show File;
import 'package:path/path.dart' as pathos;
import 'package:analyzer/src/generated/engine.dart';
import 'package:secdart_analyzer/src/supported_subset.dart';

/**
 * This class invokes the security analysis. It used mainly
 * for test and for the REST API.
 */
class SecAnalyzer {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
  DartSdk sdk;
  AnalysisContext context;

  bool returnDartErrors = false;

  bool addTasks;

  SecAnalyzer([this.addTasks = false]) {
    _setUp();
  }

  void _setUp() {
    sdk = getDarkSdk();

    context = createAnalysisContext(addTasks);
    final packageMap = <String, List<Folder>>{
      "secdart": [resourceProvider.getFolder("/secdart")]
    };
    final packageResolver =
        new PackageMapUriResolver(resourceProvider, packageMap);
    final sf = new SourceFactory([
      new DartUriResolver(sdk),
      packageResolver,
      new ResourceUriResolver(resourceProvider)
    ]);

    context.sourceFactory = sf;
    var secDart = _newSource("/secdart/secdart.dart", _getSecDartContent());

    Source source = secDart;
    ChangeSet changeSet = new ChangeSet()..addedSource(source);
    context.applyChanges(changeSet);
  }

  Source _newSource(String path, [String content = '']) {
    final file = resourceProvider.newFile(path, content);
    final source = file.createSource();
    return source;
  }

  void addSource(Source source) {
    ChangeSet changeSet = new ChangeSet()..addedSource(source);
    context.applyChanges(changeSet);
  }

  String _getSecDartContent() {
    return '''
    /*
This file contains the annotations that represents labels in a flat lattice of security
(BOT < LOW < HIGH < TOP)
*/

const high = const High();
const low= const Low();
const top= const Top();
const bot= const Bot();
const dynl = const DynLabel();

/**
 * Represents a high confidentiality label
 */
class High{
  const High();
}
/**
 * Represents a low confidentiality label
 */
class Low{
  const Low();
}

/**
 * Represents the top in the lattice
 */
class Top{
  const Top();
}
/**
 * Represents the bottom in the lattice
 */
class Bot{
  const Bot();
}

/**
 * Label for function annotations
 */
class latent{
  /**
   * The label required to invoke the function
   */
  final String beginLabel;

  /**
   * The label of the return value of the function can not be higher than the [endlabel]
   */
  final String endLabel;
  const latent(this.beginLabel,this.endLabel);
}

class DynLabel{
  const DynLabel();
}
T declassify<T>(T expression,label) => expression;
    ''';
  }

  SecAnalysisResult analyze(String program, [bool useInterval = false]) {
    Source programSource = _newSource("/test.dart", program);

    return computeAllErrors(context, programSource,
        intervalMode: useInterval, addTask: addTasks);
  }

  SecAnalysisResult analyzeFile(String filePath, [bool useInterval = false]) {
    if (!(new io.File(filePath).existsSync())) {
      throw new ArgumentError("filePath does not exist");
    }
    var absolutePath = pathos.absolute(filePath);

    var context = createAnalysisContext();
    Source source =
        context.sourceFactory.forUri(pathos.toUri(absolutePath).toString());

    return computeAllErrors(context, source,
        intervalMode: useInterval, addTask: addTasks);
  }

  static SecAnalysisResult computeAllErrors(
      AnalysisContext context, Source source,
      {bool returnDartErrors: true,
      bool intervalMode: false,
      bool addTask: false}) {
    //var libraryElement = context.computeLibraryElement(source);
    var libraryElement = null;
    if (addTask) {
      libraryElement = context.computeResult(source, SEC_ELEMENT);
    } else {
      libraryElement = context.computeResult(source, LIBRARY_ELEMENT);
    }
    var unit = libraryElement.unit;
    //var libraryElement = context.computeLibraryElement(source);
    //var unit = context.resolveCompilationUnit(source, libraryElement);

    var dartErrors = context.computeErrors(source);
    var badErrors = dartErrors.where((e) =>
        e.errorCode.errorSeverity == ErrorSeverity.ERROR ||
        e.errorCode.errorSeverity == ErrorSeverity.WARNING);
    if (badErrors.length > 0 && returnDartErrors)
      return new SecAnalysisResult(dartErrors, unit);

    return new SecAnalysisResult(computeErrors(unit, intervalMode), unit);
  }

  static List<AnalysisError> computeErrors(CompilationUnit resolvedUnit,
      [bool intervalMode = false]) {
    ErrorCollector errorListener = new ErrorCollector();

    //TODO: put this in another place
    if (!isValidSecDartFile(resolvedUnit)) {
      return errorListener.errors;
    }

    //parse element
    var parserVisitor = new SecurityParserVisitor(errorListener, intervalMode);
    resolvedUnit.accept(parserVisitor);
    if (errorListener.errors.length > 0) return errorListener.errors;

    var supportedDart = new UnSupportedDartSubsetVisitor(errorListener);
    resolvedUnit.accept(supportedDart);
    if (errorListener.errors.length > 0) return errorListener.errors;

    var secResolver = new SecurityResolverVisitor(errorListener, intervalMode);
    resolvedUnit.accept(secResolver);

    GradualSecurityTypeSystem typeSystem = new GradualSecurityTypeSystem();
    var visitor =
        new SecurityCheckerVisitor(typeSystem, errorListener, intervalMode);
    resolvedUnit.accept(visitor);

    return errorListener.errors;
  }

  static bool isValidSecDartFile(CompilationUnit unitAst) {
    return unitAst.directives
            .where((x) => x is ImportDirective)
            .map((y) => y as ImportDirective)
            .where((import) => import.uriContent.contains("package:secdart/"))
            .length >
        0;
  }
}

class SecAnalysisResult {
  List<AnalysisError> errors;
  AstNode astNode;
  SecAnalysisResult(this.errors, this.astNode);
}
