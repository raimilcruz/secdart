import 'package:analysis_server/starter.dart';

import 'package:plugin/plugin.dart';
import 'package:secdart_server_plugin/plugin.dart';
import 'package:secdart_analyzer_plugin/starter.dart' as sec;

/**
 * Create and run an analysis server with the SecDart plugins.
 */
void main(List<String> args) {
  final starter = new ServerStarter();
  starter.userDefinedPlugins = <Plugin>[
    //new SecDartServerPlugin(),
    //new MyAnalysisPlugin()
  ];
  //starter.start(args);
  final server = starter.start(args);

  new sec.Starter().start(server);
}