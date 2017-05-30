import 'package:safe_config/safe_config.dart';

/**
 * Helper class to read configuration properties
 */
class ApplicationConfiguration extends ConfigurationItem {
  ApplicationConfiguration(String fileName) :
        super.fromFile(fileName);

  String secdart_lattice_package;
}