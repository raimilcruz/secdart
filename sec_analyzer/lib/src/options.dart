import 'package:yaml/yaml.dart';

class SecDartOptions {
  SecDartOptions({this.intervalMode});
  factory SecDartOptions.from(String contents) =>
      new _OptionsBuilder(contents).build();
  factory SecDartOptions.defaults() => new _OptionsBuilder.empty().build();

  final bool intervalMode;
}

class _OptionsBuilder {
  dynamic analysisOptions;
  dynamic secDartOptions;
  dynamic secDartPluginOptions;

  bool intervalMode = false;

  _OptionsBuilder.empty();
  _OptionsBuilder(String contents) : analysisOptions = loadYaml(contents) {
    load();
  }

  void resolve() {
    intervalMode = getOption('intervals', isBoolean) ?? false;
  }

  SecDartOptions build() => new SecDartOptions(intervalMode: intervalMode);

  void load() {
    if (analysisOptions['analyzer'] == null ||
        analysisOptions['analyzer']['plugins'] == null) {
      return;
    }

    // default path
    secDartOptions = optionsIfEnabled('secdart');
    // specific-version path
    secDartPluginOptions = optionsIfEnabled('secdart_analyzer_plugin');

    if ((secDartOptions ?? secDartPluginOptions) != null) {
      resolve();
    }
  }

  dynamic optionsIfEnabled(String key) {
    final section = analysisOptions['analyzer']['plugins'][key];
    if (section != null && section['enabled'] != true) {
      return null;
    }
    return section;
  }

  dynamic getOption(String key, bool validator(input)) {
    if (secDartOptions != null && validator(secDartOptions[key])) {
      return secDartOptions[key];
    } else if (secDartPluginOptions != null &&
        validator(secDartPluginOptions[key])) {
      return secDartPluginOptions[key];
    }
    return null;
  }

  bool isBoolean(val) => val is bool;
}
