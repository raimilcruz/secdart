// This file contains classes and functions that help to build test

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:front_end/src/base/source.dart';
import 'package:secdart_analyzer/analyzer.dart';
import 'package:secdart_analyzer/src/context.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/errors.dart';
import 'package:secdart_analyzer/src/parser_visitor.dart';
import 'package:secdart_analyzer/src/supported_subset.dart';
import 'package:analyzer/source/package_map_resolver.dart';



class AbstractSecDartTest{
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
  DartSdk sdk;
  AnalysisContext context;

  Source newSource(String path, [String content = '']) {
    final file = resourceProvider.newFile(path, content);
    final source = file.createSource();
    return source;
  }
  void addSource(Source source){
    ChangeSet changeSet = new ChangeSet()..addedSource(source);
    context.applyChanges(changeSet);
  }

  void setUp() {
    sdk = getDarkSdk();

    context = createAnalysisContext();

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

    context.sourceFactory =sf;
    var secDart = newSource("/secdart/secdart.dart",_getSecDartContent());

    Source source = secDart;
    ChangeSet changeSet = new ChangeSet()..addedSource(source);
    context.applyChanges(changeSet);
  }
  String _getSecDartContent(){
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
    ''';
  }

  List<AnalysisError> typeCheckSecurityForSource(Source source,{bool intervalMode:false,
    bool printError:true}){
   var errors = SecAnalyzer.computeAllErrors(context,source,
       intervalMode: intervalMode).errors;
    if(printError){
      for(AnalysisError error in errors){
        print(error);
      }
    }
    return errors;
  }
  SecAnalysisResult resolveDart(Source source,{bool printErrors:false}){
    var libraryElement = context.computeLibraryElement(source);
    var unit = context.resolveCompilationUnit(source, libraryElement);

    var dartErrors = context.getErrors(source).errors;
    return new SecAnalysisResult(dartErrors,unit);
  }


  bool containsOnlySupportedFeatures(Source source,{bool printError:true}){
    var libraryElement = context.computeLibraryElement(source);
    var unit = context.resolveCompilationUnit(source, libraryElement);

    ErrorCollector errorListener = new ErrorCollector();

    var visitor = new UnSupportedDartSubsetVisitor(errorListener);
    unit.accept(visitor);

    if(printError){
      for(AnalysisError error in errorListener.errors){
        print(error);
      }
    }
    return errorListener.errors.where(
            (e)=>
              e.errorCode ==
                  SecurityErrorCode.UNSUPPORTED_DART_FEATURE).isEmpty;
  }
  bool containsParseErrors(Source source,{bool printError:true}){
    var libraryElement = context.computeLibraryElement(source);
    var unit = context.resolveCompilationUnit(source, libraryElement);

    ErrorCollector errorListener = new ErrorCollector();

    var visitor = new SecurityParserVisitor(errorListener);
    unit.accept(visitor);

    if(printError){
      for(AnalysisError error in errorListener.errors){
        print(error);
      }
    }
    return errorListener.errors.where((e)=>
    e.errorCode is ParserErrorCode).isNotEmpty;
  }
  bool containsInvalidFlow(List<AnalysisError> errors){
    return errors.where((e)=> e.errorCode is SecurityErrorCode).isNotEmpty;
  }
  bool containsUnsupportedFeature(List<AnalysisError> errors){
    return errors.where((e)=> e.errorCode is
      UnsupportedFeatureErrorCode).isNotEmpty;
  }
}

class AstQuery{
  static List<AstNode> toList(AstNode node){
    var nodes = <AstNode>[];
    var firstVisitor = new _NodeVisitor(nodes);
    node.accept(firstVisitor);
    return nodes;
  }
}
class _NodeVisitor extends GeneralizingAstVisitor<Object> {
  List<AstNode> nodes;
  _NodeVisitor(this.nodes) : super();

  @override
  Object visitNode(AstNode node) {
    nodes.add(node);
    return super.visitNode(node);
  }
}
