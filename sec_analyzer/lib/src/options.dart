import 'package:yaml/yaml.dart';

class SecDartOptions {
  SecDartOptions({this.intervalMode, this.latticePath});

  factory SecDartOptions.from(String contents) =>
      new _OptionsBuilder(contents).build();

  factory SecDartOptions.defaults() => new _OptionsBuilder.empty().build();

  final bool intervalMode;

  final String latticePath;
}

class _OptionsBuilder {
  dynamic analysisOptions;
  dynamic secDartOptions;
  dynamic secDartPluginOptions;

  bool intervalMode = false;
  String latticePath;

  _OptionsBuilder.empty();

  _OptionsBuilder(String contents) : analysisOptions = loadYaml(contents) {
    load();
  }

  void resolve() {
    intervalMode = getOption('intervals', isBoolean) ?? false;
    latticePath = getOption("lattice", (v) => v is String) ?? "";
  }

  SecDartOptions build() =>
      new SecDartOptions(intervalMode: intervalMode, latticePath: latticePath);

  void load() {
    if (analysisOptions['analyzer'] == null ||
        analysisOptions['analyzer']['plugins'] == null) {
      return;
    }

    // default path
    secDartOptions = loadPluginOptions('secdart');

    if ((secDartOptions) != null) {
      resolve();
    }
  }

  dynamic loadPluginOptions(String key) {
    final plugins = analysisOptions['analyzer']['plugins'];

    if (plugins is! Map) {
      return null;
    }

    return plugins.containsKey(key) ? plugins[key] : null;
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

class LatticeConfig {
  List<String> elements;
  List<LabelOrder> order;
  String top;
  String bottom;
  String unknown;

  LatticeConfig(this.elements, this.order, this.top, this.bottom,
      [this.unknown = "?"]);

  static LatticeConfig from(LatticeFile latticeFile) {
    if (latticeFile.bottom == null ||
        latticeFile.elements == null ||
        latticeFile.elements.length == 0 ||
        latticeFile.top == null ||
        latticeFile.order == null ||
        latticeFile.order.length == 0) return defaultLattice;
    if (_validateIsALattice(latticeFile)) {
      return new LatticeConfig(latticeFile.elements, latticeFile.order,
          latticeFile.top, latticeFile.bottom);
    }
    return defaultLattice;
  }

  static final LatticeConfig defaultLattice = new LatticeConfig([
    "bot",
    "L",
    "H",
    "top"
  ], [
    new LabelOrder("bot", "L"),
    new LabelOrder("L", "H"),
    new LabelOrder("H", "top")
  ], "top", "bot");

  static bool _validateIsALattice(LatticeFile latticeFile) {
    return false;
  }
}

class LatticeFile {
  final String name;
  final List<String> elements;
  final List<LabelOrder> order;
  final String top;
  final String bottom;

  LatticeFile(this.name, this.elements, this.order, this.top, this.bottom);

  factory LatticeFile.from(String contents) =>
      new _LatticeBuilder(contents).build();
}

class LabelOrder {
  String s1, s2;

  LabelOrder(this.s1, this.s2);

  @override
  String toString() => "$s1 <= $s2";

  @override
  bool operator ==(other) {
    if (other is LabelOrder) {
      return other.s2 == s2 && other.s1 == s1;
    }
    return false;
  }

  @override
  int get hashCode => toString().hashCode;
}

class _LatticeBuilder {
  dynamic latticeYaml;
  String latticeName;
  List<String> elements = [];
  List<LabelOrder> order = [];
  String top, bottom;

  bool formatError;

  _LatticeBuilder(String contents) : latticeYaml = loadYaml(contents) {
    load();
  }

  LatticeFile build() =>
      new LatticeFile(latticeName, elements, order, top, bottom);

  void load() {
    if (latticeYaml == null ||
        latticeYaml['name'] == null ||
        latticeYaml['elements'] == null ||
        latticeYaml['order'] == null ||
        latticeYaml['top'] == null ||
        latticeYaml['bottom'] == null) {
      formatError = true;
      return;
    }
    resolve();
  }

  void resolve() {
    latticeName = getOption('name', (val) => val is String) ?? "";
    elements = getOption('elements', isListOfStrings)?.cast<String>() ?? [];
    getOption('order', isListOfOrders)?.nodes?.forEach((orderNode) {
      order.add(_orderFromString(orderNode.value));
    });

    bottom = getOption('bottom', (val) => val is String) ?? "";
    top = getOption('top', (val) => val is String) ?? "";
  }

  dynamic getOption(String key, bool validator(input)) {
    if (latticeYaml != null && validator(latticeYaml[key])) {
      return latticeYaml[key];
    }
    return null;
  }

  LabelOrder _orderFromString(String val) {
    final parts = val.split("<=");
    return new LabelOrder(parts[0].trim(), parts[1].trim());
  }

  bool isListOfStrings(values) =>
      values is List && values.every((value) => value is String);

  bool isListOfOrders(values) =>
      values is List &&
      values.every((value) => value is String && value.split("<=").length == 2);
}
