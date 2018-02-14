import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/src/task/general.dart';
import 'package:analyzer/task/model.dart';
import 'package:analyzer/task/dart.dart';
import 'package:front_end/src/base/source.dart';
import 'package:secdart_analyzer/analyzer.dart';
import 'package:secdart_analyzer/src/error_collector.dart';
import 'package:secdart_analyzer/src/security_resolver.dart';
import 'package:secdart_analyzer/src/supported_subset.dart';
import 'package:secdart_analyzer/src/parser_visitor.dart';
import 'package:secdart_analyzer/src/gs_typesystem.dart';
import 'package:secdart_analyzer/src/security_visitor.dart';

/**
 * The analysis errors associated with a [Source] representing a compilation
 * unit.
 */

final ResultDescriptor<LibraryElement> SEC_ELEMENT =
    new ResultDescriptor<LibraryElement>('SEC_ELEMENT', null);

final ResultDescriptor<bool> READY_SECURITY_ANALYSIS =
    new ResultDescriptor<bool>('READY_SECURITY_ANALYSIS', false);

final ListResultDescriptor<AnalysisError> SEC_PARSER_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'SEC_PARSER_ERRORS', AnalysisError.NO_ERRORS);

final ListResultDescriptor<AnalysisError> SECDART_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'SECDART_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The parsing process is ready of the library
 */
final ResultDescriptor<bool> READY_SEC_LIBRARY_ELEMENT1 =
    new ResultDescriptor<bool>('READY_SEC_LIBRARY_ELEMENT1', false);

final ResultDescriptor<LibraryElement> SEC_LIBRARY_ELEMENT_1 =
    new ResultDescriptor<LibraryElement>('SEC_LIBRARY_ELEMENT_1', null,
        cachingPolicy: ELEMENT_CACHING_POLICY);
/**
 *
 */
final ResultDescriptor<CompilationUnit> SEC_RESOLVED_UNIT1 =
    new ResultDescriptor<CompilationUnit>('SEC_RESOLVED_UNIT1', null,
        cachingPolicy: AST_CACHING_POLICY);

/**
 * Invoke the security parser for an specific unit
 */
class ResolveSecurityAnnotationTask extends SourceBasedAnalysisTask {
  static const String UNIT_INPUT = 'RESOLVED_UNIT_INPUT';

  static TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolveSecurityAnnotationTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[SEC_RESOLVED_UNIT1, SEC_PARSER_ERRORS]);

  ResolveSecurityAnnotationTask(AnalysisContext context, AnalysisTarget target)
      : super(context, target);

  // TODO: implement descriptor
  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    CompilationUnit unit = getRequiredInput(UNIT_INPUT);
    //invoke here the security parser
    ErrorCollector errorListener = new ErrorCollector();

    if (SecAnalyzer.isValidSecDartFile(unit)) {
      var parserVisitor = new SecurityParserVisitor(errorListener, false);
      unit.accept(parserVisitor);

      if (errorListener.errors.isEmpty) {
        var resolverVisitor = new SecurityResolverVisitor(errorListener, false);
        unit.accept(resolverVisitor);
      }
    }

    outputs[SEC_PARSER_ERRORS] = errorListener.errors;
    outputs[SEC_RESOLVED_UNIT1] = unit;
  }

  static ResolveSecurityAnnotationTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolveSecurityAnnotationTask(context, target);
  }

  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      UNIT_INPUT: RESOLVED_UNIT.of(unit),
    };
  }
}

class ResolvedSecurityUnit1InLibraryTask extends SourceBasedAnalysisTask {
  static const String RESOLVED_UNIT_INPUT = 'RESOLVED_UNIT';
  static const String LIBRARY_INPUT = 'LIBRARY_INPUT';

  ResolvedSecurityUnit1InLibraryTask(
      AnalysisContext context, AnalysisTarget target)
      : super(context, target);

  static TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ResolvedSecurityUnit1InLibraryTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[SEC_LIBRARY_ELEMENT_1]);

  // TODO: implement descriptor
  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    //LibraryElement library = getRequiredInput(LIBRARY_INPUT);
    outputs[SEC_LIBRARY_ELEMENT_1] = null;
  }

  static ResolvedSecurityUnit1InLibraryTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ResolvedSecurityUnit1InLibraryTask(context, target);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      'resolvedUnits':
          LIBRARY_SPECIFIC_UNITS.of(source).toListOf(SEC_RESOLVED_UNIT1),
    };
  }
}

class ReadySecurityInformationForLibraryTask extends SourceBasedAnalysisTask {
  static const String SEC_ANNOTATION_INPUT = 'SEC_ANNOTATION_INPUT';

  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'ReadySecurityInformationForLibraryTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[READY_SEC_LIBRARY_ELEMENT1]);

  ReadySecurityInformationForLibraryTask(
      AnalysisContext context, AnalysisTarget target)
      : super(context, target);

  // TODO: implement descriptor
  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  bool get handlesDependencyCycles => true;

  @override
  void internalPerform() {
    outputs[READY_SEC_LIBRARY_ELEMENT1] = true;
  }

  static ReadySecurityInformationForLibraryTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new ReadySecurityInformationForLibraryTask(context, target);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      //parse this source
      'thisLibrarySecAnnotationReady': SEC_LIBRARY_ELEMENT_1.of(source),
      //request to analyze imported files
      'directlyImportedLibrariesReady':
          IMPORTED_LIBRARIES.of(source).toListOf(READY_SEC_LIBRARY_ELEMENT1),
    };
  }
}

class GradualSecurityVerifyUnitTask extends SourceBasedAnalysisTask {
  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'GradualSecurityVerifyUnitTask',
      createTask,
      buildInputs,
      <ResultDescriptor>[SECDART_ERRORS, READY_SECURITY_ANALYSIS]);

  /**
   * The name of the [SEC_ANNOTATION_PARSED_INPUT] input.
   */
  static const String SEC_ANNOTATION_PARSED_INPUT =
      'SEC_ANNOTATION_PARSED_INPUT';

  static const String UNIT_INPUT = 'RESOLVED_UNIT_INPUT';

  static const String SEC_RESOLVED_UNIT_INPUT = 'SEC_RESOLVED_UNIT_INPUT';

  GradualSecurityVerifyUnitTask(AnalysisContext context, AnalysisTarget target)
      : super(context, target);

  // TODO: implement descriptor
  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    CompilationUnit unit = getRequiredInput(SEC_RESOLVED_UNIT_INPUT);
    ErrorCollector errorListener = new ErrorCollector();

    var supportedDart = new UnSupportedDartSubsetVisitor(errorListener);
    unit.accept(supportedDart);

    if (errorListener.errors.isEmpty) {
      GradualSecurityTypeSystem typeSystem = new GradualSecurityTypeSystem();
      var visitor =
          new SecurityCheckerVisitor(typeSystem, errorListener, false);
      unit.accept(visitor);
    }

    outputs[SECDART_ERRORS] = errorListener.errors;
    outputs[READY_SECURITY_ANALYSIS] = true;
  }

  static GradualSecurityVerifyUnitTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new GradualSecurityVerifyUnitTask(context, target);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    LibrarySpecificUnit unit = target;
    return <String, TaskInput>{
      SEC_ANNOTATION_PARSED_INPUT: READY_SEC_LIBRARY_ELEMENT1.of(unit.library),
      SEC_RESOLVED_UNIT_INPUT: SEC_RESOLVED_UNIT1.of(unit),
      //UNIT_INPUT: RESOLVED_UNIT.of(unit),
    };
  }
}

class SecurityTask extends SourceBasedAnalysisTask {
  /**
   * The task descriptor describing this kind of task.
   */
  static final TaskDescriptor DESCRIPTOR = new TaskDescriptor(
      'SecurityTask', createTask, buildInputs, <ResultDescriptor>[SEC_ELEMENT]);

  /**
   * The name of the [RESOLVED_UNIT_INPUT] input.
   */
  static const String RESOLVED_UNIT_INPUT = 'RESOLVED_UNIT_INPUT';

  /**
   * The name of the [READY_SECURITY_ANALYSIS_INPUT] input.
   */
  static const String SECURITY_ANALYSIS_INPUT = 'SECURITY_ANALYSIS';

  SecurityTask(AnalysisContext context, AnalysisTarget target)
      : super(context, target);

  // TODO: implement descriptor
  @override
  TaskDescriptor get descriptor => DESCRIPTOR;

  @override
  void internalPerform() {
    LibraryElement element = getRequiredInput(RESOLVED_UNIT_INPUT);
    outputs[SEC_ELEMENT] = element;
    // TODO: implement internalPerform
  }

  @override
  bool get handlesDependencyCycles => true;

  static SecurityTask createTask(
      AnalysisContext context, AnalysisTarget target) {
    return new SecurityTask(context, target);
  }

  /**
   * Return a map from the names of the inputs of this kind of task to the task
   * input descriptors describing those inputs for a task with the given
   * [target].
   */
  static Map<String, TaskInput> buildInputs(AnalysisTarget target) {
    Source source = target;
    return <String, TaskInput>{
      RESOLVED_UNIT_INPUT: LIBRARY_ELEMENT.of(source),
      //"errorsReady": LIBRARY_ERRORS_READY.of(source),
      SECURITY_ANALYSIS_INPUT:
          LIBRARY_SPECIFIC_UNITS.of(source).toListOf(READY_SECURITY_ANALYSIS),
    };
  }
}
