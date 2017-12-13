import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:secdart_analyzer_plugin/plugin.dart';
import 'package:secdart_analyzer_plugin/src/secdriver.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:test/test.dart';


void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginIntegrationTest);
  });
}

@reflectiveTest
class PluginIntegrationTest extends AnalysisOptionsUtilsBase {
  void test_createAnalysisDriver() {
    enableAnalyzerPluginSecDart();
    final SecDriver driver = plugin.createAnalysisDriver(root);
    expect(driver, isNotNull);
  }

  void test_createAnalysisDriver_containsDartDriver() {
    enableAnalyzerPluginSecDart();
    final SecDriver driver = plugin.createAnalysisDriver(root);

    expect(driver, isNotNull);
    expect(driver.dartDriver, isNotNull);
    expect(driver.dartDriver.analysisOptions, isNotNull);
    expect(driver.dartDriver.fsState, isNotNull);
    expect(driver.dartDriver.sourceFactory, isNotNull);
    expect(driver.dartDriver.contextRoot, isNotNull);
  }


  void test_createAnalysisDriver_defaultOptions() {
    enableAnalyzerPluginSecDart();
    final SecDriver driver = plugin.createAnalysisDriver(root);

    expect(driver, isNotNull);
    expect(driver.options, isNotNull);
    expect(driver.options.intervalMode, isFalse);
  }


  void test_createAnalysisDriver_intervalModel() {
    enableAnalyzerPluginSecDart(extraOptions: [
      'intervals: true',
      '  - foo',
      '  - bar',
      '  - baz',
    ]);
    final SecDriver driver = plugin.createAnalysisDriver(root);

    expect(driver, isNotNull);
    expect(driver.options, isNotNull);
    expect(driver.options.intervalMode, isFalse);
  }
}

/// Unfortunately, package:yaml doesn't support dumping to yaml. So this is
/// what we are stuck with, for now. Put it in a base class so we can test it
class AnalysisOptionsUtilsBase {
  SecDartPlugin plugin;
  MemoryResourceProvider resourceProvider;
  protocol.ContextRoot root;

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    plugin = new SecDartPlugin(resourceProvider);
    final versionCheckParams = new protocol.PluginVersionCheckParams(
        "~/.dartServer/.analysis-driver", "/sdk", "1.0.0");
    plugin.handlePluginVersionCheck(versionCheckParams);
    root = new protocol.ContextRoot("/test", [],
        optionsFile: '/test/analysis_options.yaml');
  }

  void enableAnalyzerPluginSecDart({List<String> extraOptions = const []}) =>
      setOptionsFileContent(optionsHeader +
          optionsSection('secdart',
              extraOptions: ['enabled: true']..addAll(extraOptions)));


  String optionsHeader = '''
analyzer:
  plugins:
''';

  String optionsSection(String key, {List<String> extraOptions = const []}) =>
      '''
    $key:
${extraOptions.map((option) => """
      $option
""").join('')}
''';

  void setOptionsFileContent(String content) {
    resourceProvider.newFile('/test/analysis_options.yaml', content);
  }
}

