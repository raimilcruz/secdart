// This file contains classes and functions that help to build test

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:secdart_analyzer/analyzer.dart';
import 'package:secdart_analyzer/security_label.dart';
import 'package:secdart_analyzer/security_type.dart';
import 'package:secdart_analyzer/src/annotations/parser.dart';
import 'package:secdart_analyzer/src/annotations/parser_element.dart';
import 'package:secdart_analyzer/src/app_config.dart';
import 'package:secdart_analyzer/src/configuration.dart';
import 'package:secdart_analyzer/src/context.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/errors.dart';
import 'package:secdart_analyzer/src/options.dart';
import 'package:secdart_analyzer/src/parser_visitor.dart';
import 'package:secdart_analyzer/src/security_label.dart';
import 'package:secdart_analyzer/src/security_type.dart';
import 'package:secdart_analyzer/src/supported_subset.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:secdart_analyzer/src/security_resolver.dart';
import 'package:path/path.dart' as pathos;

final SecAnalysisConfig defaultConfig =
    new SecAnalysisConfig(false, LatticeConfig.defaultLattice);
final SecAnalysisConfig intervalModeWithDefaultLatticeConfig =
    new SecAnalysisConfig(true, LatticeConfig.defaultLattice);

final aliceBobLattice = new LatticeConfig([
  "Alice",
  "Bob",
  "T",
  "B"
], [
  new LabelOrder("Alice", "T"),
  new LabelOrder("Bob", "T"),
  new LabelOrder("B", "Alice"),
  new LabelOrder("B", "Bob")
], "T", "B");

class AbstractSecDartTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
  DartSdk sdk;
  AnalysisContext context;

  Source newSource(String path, [String content = '']) {
    final file =
        resourceProvider.newFile(new pathos.Context().normalize(path), content);
    final source = file.createSource();
    return source;
  }

  void addSource(Source source) {
    ChangeSet changeSet = new ChangeSet()..addedSource(source);
    context.applyChanges(changeSet);
  }

  void setUp() {
    sdk = getDarkSdk();

    context = createAnalysisContext();

    final packageMap = <String, List<Folder>>{
      "secdart": [
        resourceProvider.getFolder(new pathos.Context().normalize("/secdart"))
      ]
    };
    final packageResolver =
        new PackageMapUriResolver(resourceProvider, packageMap);
    final sf = new SourceFactory([
      new DartUriResolver(sdk),
      packageResolver,
      new ResourceUriResolver(resourceProvider)
    ]);

    context.sourceFactory = sf;
    var secDart = newSource("/secdart/secdart.dart", _getSecDartContent());

    Source source = secDart;
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

  List<AnalysisError> typeCheckSecurityForSource(Source source,
      {bool printError: true,
      bool includeDartErrors: false,
      SecAnalysisConfig config = null,
      bool customLattice = false}) {
    if (config == null) {
      config = defaultConfig;
    }
    var errors = SecAnalyzer.computeAllErrors(context, source, config,
            returnDartErrors: includeDartErrors, customLattice: customLattice)
        .errors;
    if (printError && AppConfiguration.defaultConfig().isDebug) {
      for (AnalysisError error in errors) {
        print(error);
      }
    }
    return errors;
  }

  SecAnalysisResult resolveDart(Source source, {bool printErrors: false}) {
    var libraryElement = context.computeLibraryElement(source);
    var unit = context.resolveCompilationUnit(source, libraryElement);

    var dartErrors = context.getErrors(source).errors;
    return new SecAnalysisResult(dartErrors, unit);
  }

  bool containsOnlySupportedFeatures(Source source, {bool printError: true}) {
    var libraryElement = context.computeLibraryElement(source);
    var unit = context.resolveCompilationUnit(source, libraryElement);

    ErrorCollector errorListener = new ErrorCollector();

    var visitor = new UnSupportedDartSubsetVisitor(errorListener);
    unit.accept(visitor);

    if (printError && AppConfiguration.defaultConfig().isDebug) {
      for (AnalysisError error in errorListener.errors) {
        print(error);
      }
    }
    return errorListener.errors
        .where((e) => e.errorCode == SecurityErrorCode.UNSUPPORTED_DART_FEATURE)
        .isEmpty;
  }

  SecAnalysisResult parse(Source source,
      [SecAnalysisConfig config = null,
      bool customLattice = false,
      bool includeDartErrors = false]) {
    if (config == null) {
      config = defaultConfig;
    }

    var result = resolveDart(source);
    if (includeDartErrors) {
      return result;
    }
    ErrorCollector errorListener = new ErrorCollector();
    var unit = result.astNode;

    SecAnnotationParser parser =
        _getParser(errorListener, unit, customLattice, config);
    var visitor = new SecurityParserVisitor(errorListener, unit, parser, true);
    unit.accept(visitor);

    return new SecAnalysisResult(errorListener.errors, unit);
  }

  SecurityElementResolver parseAndGetSecurityElementResolver(
      CompilationUnit unit, ErrorCollector errorListener,
      [SecAnalysisConfig config = null, bool customLattice = false]) {
    if (config == null) {
      config = defaultConfig;
    }

    SecAnnotationParser annotationParser =
        _getParser(errorListener, unit, customLattice, config);

    SecDartConfig.init(config.latticeConfig);
    var visitor =
        new SecurityParserVisitor(errorListener, unit, annotationParser, true);
    unit.accept(visitor);

    SecurityCache securityCache = new SecurityCache();

    GradualLattice lattice = _getGradualLattice(config);

    var secDartElementResolver = new SecDartElementResolver(
        unit, annotationParser, securityCache, visitor.labeMap, lattice);

    var nonSecDartElementResolver =
        new ExternalLibraryResolver(lattice, securityCache);

    final resolver = new DispatcherSecurityElementResolver(
        secDartElementResolver, nonSecDartElementResolver, securityCache);
    return resolver;
  }

  GradualLattice _getGradualLattice(SecAnalysisConfig config) {
    GradualLattice lattice = null;
    if (config.intervalMode) {
      lattice = new IntervalLattice(config.latticeConfig);
    } else {
      lattice = new GradualLatticeWithUnknown(config.latticeConfig);
    }
    return lattice;
  }

  SecAnnotationParser _getParser(ErrorCollector errorListener,
      CompilationUnit unit, bool customLattice, SecAnalysisConfig config) {
    SecAnnotationParser annotationParser =
        new FourLatticeParser(errorListener, unit);
    if (customLattice) {
      annotationParser = new ConfigurableLatticeParser(
          config.latticeConfig, errorListener, unit);
    }
    return annotationParser;
  }

  SecResolverResult resolveSecurity(Source source,
      [SecAnalysisConfig config = null, bool customLattice = false]) {
    if (config == null) {
      config = defaultConfig;
    }
    var result = resolveDart(source);
    if (result.errors.isNotEmpty) {
      return result;
    }
    ErrorCollector errorListener = new ErrorCollector();
    var unit = result.astNode;

    SecAnnotationParser annotationParser =
        _getParser(errorListener, unit, customLattice, config);

    SecDartConfig.init(config.latticeConfig);

    var visitor =
        new SecurityParserVisitor(errorListener, unit, annotationParser, true);
    unit.accept(visitor);

    SecurityCache securityCache = new SecurityCache();

    GradualLattice lattice = _getGradualLattice(config);

    assert(lattice != null);

    var secDartResolver = new SecDartElementResolver(
        unit, annotationParser, securityCache, visitor.labeMap, lattice);
    var nonSecDartResolver =
        new ExternalLibraryResolver(lattice, securityCache);

    var elementResolver = new DispatcherSecurityElementResolver(
        secDartResolver, nonSecDartResolver, securityCache);

    var topLevelResolver = new TopLevelDeclarationResolver(elementResolver);
    unit.accept(topLevelResolver);

    var fullResolver = new SecurityResolverVisitor(
        errorListener, elementResolver, securityCache);

    unit.accept(fullResolver);

    return new SecResolverResult(
        errorListener.errors, unit, fullResolver.securityMap);
  }

  void resolveTopLevelDeclarations(
      CompilationUnit unit,
      ErrorCollector errorListener,
      SecAnalysisConfig config,
      bool customLattice) {
    assert(config != null);
    assert(config.latticeConfig != null);
    var annotationParser =
        _getParser(errorListener, unit, customLattice, config);
    var visitor =
        new SecurityParserVisitor(errorListener, unit, annotationParser, true);
    unit.accept(visitor);

    SecurityCache securityCache = new SecurityCache();
    GradualLattice lattice = _getGradualLattice(config);

    var secDartResolver = new SecDartElementResolver(
        unit, annotationParser, securityCache, visitor.labeMap, lattice);

    var nonSecDartResolver =
        new ExternalLibraryResolver(lattice, securityCache);

    var elementResolver = new DispatcherSecurityElementResolver(
        secDartResolver, nonSecDartResolver, securityCache);

    var topLevelResolver = new TopLevelDeclarationResolver(elementResolver);
    unit.accept(topLevelResolver);
  }

  bool containsInvalidFlow(List<AnalysisError> errors) {
    return errors.where((e) => e.errorCode is SecurityErrorCode).isNotEmpty;
  }

  bool containsUnsupportedFeature(List<AnalysisError> errors) {
    return errors
        .where((e) => e.errorCode is UnsupportedFeatureErrorCode)
        .isNotEmpty;
  }
}

class AstQuery {
  static List<AstNode> toList(AstNode node) {
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

class SecResolverResult extends SecAnalysisResult {
  SecurityCache elementCache;

  SecResolverResult(
      List<AnalysisError> errors, AstNode astNode, this.elementCache)
      : super(errors, astNode);
}

class FunctionSecurityTypeLabelShape {
  SecurityLabel beginLabel, endLabel, returnLabel;
  List<SecurityLabel> parameters;

  FunctionSecurityTypeLabelShape(
      this.beginLabel, this.endLabel, this.returnLabel, this.parameters);

  bool sameShapeThat(SecurityFunctionType s) {
    return beginLabel == s.beginLabel &&
        endLabel == s.endLabel &&
        returnLabel == s.returnType.label &&
        _sameParameters(
            parameters, s.argumentTypes.map((t) => t.label).toList());
  }

  static bool _sameParameters(
      List<SecurityLabel> parameters1, List<SecurityLabel> parameters2) {
    if (parameters1.length != parameters2.length) {
      return false;
    }
    for (int i = 0; i < parameters1.length; i++) {
      if (parameters1[i] != parameters2[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(other) {
    if (other is FunctionSecurityTypeLabelShape) {
      return beginLabel == other.beginLabel &&
          endLabel == other.endLabel &&
          returnLabel == other.returnLabel &&
          _sameParameters(parameters, other.parameters);
    }
    return false;
  }

  @override
  int get hashCode {
    return toString().hashCode;
  }

  @override
  String toString() {
    return "($parameters->[$beginLabel]->$returnLabel)@$endLabel";
  }
}

FunctionSecurityTypeLabelShape labelShape(SecurityFunctionType functionType) {
  return new FunctionSecurityTypeLabelShape(
      functionType.beginLabel,
      functionType.endLabel,
      functionType.returnType.label,
      functionType.argumentTypes.map((p) => p.label).toList());
}

final BotLabel = new StaticLabelImpl("bot");
final HighLabel = new StaticLabelImpl("H");
final LowLabel = new StaticLabelImpl("L");
final TopLabel = new StaticLabelImpl("top");

final GHighLabel = toGradual(HighLabel);
final GLowLabel = toGradual(LowLabel);
final GTopLabel = toGradual(TopLabel);
final GBotLabel = toGradual(BotLabel);

final IHighLabel = toInterval(HighLabel);
final ILowLabel = toInterval(LowLabel);
final ITopLabel = toInterval(TopLabel);
final IBotLabel = toInterval(BotLabel);

GradualStaticLabel toGradual(StaticLabel label) {
  return new GradualStaticLabel(label);
}

IntervalLabel toInterval(StaticLabel label) {
  return new IntervalLabel(label, label);
}
