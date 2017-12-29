import 'package:safe_config/safe_config.dart';

/**
 * Helper class to read configuration properties
 */
class ApplicationConfiguration extends ConfigurationItem {
  ApplicationConfiguration(String fileName) : super.fromFile(fileName);
  int port = 8181;
}
