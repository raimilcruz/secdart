import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:secdart_analyzer/src/context.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/gs_typesystem.dart';
import 'package:secdart_analyzer/src/helpers/resource_helper.dart';
import 'package:secdart_analyzer/src/parser_visitor.dart';
import 'package:secdart_analyzer/src/security_visitor.dart'
    show SecurityVisitor;
import 'package:analyzer/analyzer.dart' show AnalysisError, CompilationUnit;
import 'dart:io' as io show File;
import 'package:path/path.dart' as pathos;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart' show FileBasedSource;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:secdart_analyzer/src/supported_subset.dart';

/**
 * This class invokes the security analysis. It used mainly
 * for test and for the REST API.
 */
class SecAnalyzer {
  PhysicalResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  bool _checkDartErrors = false;
  final String latticeFile;

  SecAnalyzer(this.latticeFile);

  List<AnalysisError> analyze(String program, [bool useInterval = false]) {
    //TODO:Remove this workaround. Find the right way to implement this.
    var annotationsFile = latticeFile;
    var f = new io.File(annotationsFile);
    String annotationsCode = f.readAsStringSync();
    int lengthAnnotations = annotationsCode.length;

    var programAugmented = annotationsCode + program;

    ResourceHelper helper = new ResourceHelper();
    var source = helper.newSource("/test.dart", programAugmented);

    var context = createAnalysisContext();
    var unit = context.resolveCompilationUnit2(source, source);

    var dartErrors = context.getErrors(source).errors;
    if (dartErrors.length > 0) {
      for (var err in dartErrors) {
        err.offset = err.offset - lengthAnnotations;
      }
      return dartErrors;
    }
    source = helper.newSource("/test2.dart", program);
    unit = context.resolveCompilationUnit2(source, source);
    return computeErrors(unit);
  }

  List<AnalysisError> analyzeFile(String filePath, [bool useInterval = false]) {
    if (!(new io.File(filePath).existsSync())) {
      throw new ArgumentError("filePath does not exist");
    }

    var context = createAnalysisContext();
    var absolutePath = pathos.absolute(filePath);
    Source source =
        context.sourceFactory.forUri(pathos.toUri(absolutePath).toString());

    var libraryElement = context.computeLibraryElement(source);
    //var unit  = context.resolveCompilationUnit2(source, source);
    var unit = context.resolveCompilationUnit(source, libraryElement);

    var dartErrors = context.getErrors(source).errors;
    if (dartErrors.length > 0 && _checkDartErrors) return dartErrors;

    return computeErrors(unit);
  }

  List<AnalysisError> dartAnalyze(String fileSource) {
    print('working dir ${new io.File('.').resolveSymbolicLinksSync()}');

    DartSdk sdk = getDarkSdk();

    var resolvers = [
      new DartUriResolver(sdk),
      new ResourceUriResolver(PhysicalResourceProvider.INSTANCE)
    ];

    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext()
      ..sourceFactory = new SourceFactory(resolvers);

    Source source = new FileBasedSource(new JavaFile(fileSource));
    ChangeSet changeSet = new ChangeSet()..addedSource(source);
    context.applyChanges(changeSet);
    LibraryElement libElement = context.computeLibraryElement(source);

    CompilationUnit resolvedUnit =
        context.resolveCompilationUnit(source, libElement);
    return context.getErrors(source).errors;
  }

  static List<AnalysisError> computeErrors(CompilationUnit resolvedUnit){

    ErrorCollector errorListener = new ErrorCollector();

    //TODO: put this in another place
    if(!isValidSecDartFile(resolvedUnit)){
      return errorListener.errors;
    }

    //parse element
    var parserVisitor= new SecurityParserVisitor(errorListener);
    resolvedUnit.accept(parserVisitor);
    if(errorListener.errors.length>0)
      return errorListener.errors;

    var supportedDart = new UnSupportedDartSubsetVisitor(errorListener);
    resolvedUnit.accept(supportedDart);
    if(errorListener.errors.length>0)
      return errorListener.errors;

    GradualSecurityTypeSystem typeSystem = new GradualSecurityTypeSystem();

    var visitor = new SecurityVisitor(typeSystem,errorListener);
    resolvedUnit.accept(visitor);

    return errorListener.errors;
  }
  static bool isValidSecDartFile(CompilationUnit unitAst) {
    return unitAst.directives.where((x)=> x is ImportDirective).map((y)=> y as ImportDirective).
    where((import) => import.uriContent.contains("package:secdart/")).length >0;
  }
}
