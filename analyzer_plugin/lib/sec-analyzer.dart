
import 'package:analyzer/src/generated/source.dart';
import 'package:secdart_analyzer_plugin/src/borrow/context.dart';
import 'package:secdart_analyzer_plugin/src/error-collector.dart';
import 'package:secdart_analyzer_plugin/src/errors.dart';
import 'package:secdart_analyzer_plugin/src/gs-typesystem.dart';
import 'package:secdart_analyzer_plugin/src/helpers/resource_helper.dart';
import 'package:secdart_analyzer_plugin/src/security_visitor.dart' show SecurityVisitor;
import 'package:analyzer/analyzer.dart' show AnalysisError, CompilationUnit, ErrorSeverity;
import 'dart:io' show Directory, File, FileSystemEntity;
import 'package:path/path.dart' as pathos;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart' show FileBasedSource, FileUriResolver, PackageUriResolver;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_transformers/resolver.dart' show dartSdkDirectory;


/**
 * This class invokes the security analysis. It used mainly
 * for test and for the REST API.
 */
class SecAnalyzer{

  AnalysisContext _context;
  bool _checkDartErrors = false;
  bool _throwErrorForUnSupportedFeature;
  SecAnalyzer([bool throwErrorForUnSupportedFeature = true]){
    this._throwErrorForUnSupportedFeature = throwErrorForUnSupportedFeature;
  }

   List<AnalysisError> analyze(String program,[bool useInterval =false]){
     //TODO:Remove this workaround. Find the right way to implement this.
     var annotationsFile = new File('.').resolveSymbolicLinksSync()+"\\annotations\\flat-lattice.dart";
     var f = new File(annotationsFile);
     String  annotationsCode = f.readAsStringSync();
     int lengthAnnotations = annotationsCode.length;

     var programAugmented = annotationsCode + program;

     ResourceHelper helper = new ResourceHelper();
     var source= helper.newSource("/test.dart",programAugmented);

     var context = createAnalysisContext();
     var unit  = context.resolveCompilationUnit2(source, source);


     var dartErrors  = context.getErrors(source).errors;
     if(dartErrors.length>0)
     {
        for(var err in dartErrors){
          err.offset = err.offset - lengthAnnotations;
        }
       return dartErrors;
     }

     source = helper.newSource("/test2.dart",program);
     unit = context.resolveCompilationUnit2(source, source);

     ErrorCollector errorListener = new ErrorCollector();
     GradualSecurityTypeSystem typeSystem = new GradualSecurityTypeSystem();

     //invoke the security visitor
     var visitor = new SecurityVisitor(typeSystem,errorListener,useInterval);

     try {
       var accept = unit.accept(visitor);
       return errorListener.errors;
     }
     on UnimplementedError catch(e){
       if(_throwErrorForUnSupportedFeature)
         throw e;
        var r = new List<AnalysisError>();
        r.add(SecurityTypeError.getImplementationError(unit,"Unsupported feature"));
       return r;
     }
   }
  List<AnalysisError> analyzeFile(String filePath,[bool useInterval =false]){
     if(!(new File(filePath).existsSync())) {
        throw new ArgumentError("filePath does not exist");
     }

     var context = createAnalysisContext();
     var absolutePath = pathos.absolute(filePath);
     Source source = context.sourceFactory.forUri(pathos.toUri(absolutePath).toString());

     var libraryElement = context.computeLibraryElement(source);
     //var unit  = context.resolveCompilationUnit2(source, source);
     var unit  = context.resolveCompilationUnit(source, libraryElement);

     var dartErrors  = context.getErrors(source).errors;
     if(dartErrors.length>0 && _checkDartErrors)
       return dartErrors;

     ErrorCollector errorListener = new ErrorCollector();
     GradualSecurityTypeSystem typeSystem = new GradualSecurityTypeSystem();

     //invoke the security visitor
     var visitor = new SecurityVisitor(typeSystem,errorListener,useInterval);
     unit.accept(visitor);

     return errorListener.errors;
   }
  List<AnalysisError> dartAnalyze(String fileSource) {
    print('working dir ${new File('.').resolveSymbolicLinksSync()}');

    JavaSystemIO.setProperty("com.google.dart.sdk", dartSdkDirectory);
    DartSdk sdk = DirectoryBasedDartSdk.defaultSdk;

    var resolvers = [new DartUriResolver(sdk), new FileUriResolver()];

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

}