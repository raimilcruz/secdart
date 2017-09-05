import '../lib/starter.dart';
import 'package:secdart_analyzer_plugin/starter.dart' as sec;

/**
 * Create and run an analysis server with the SecDart plugins.
 */
void main(List<String> args) {
  final starter = new ServerStarter();

  final server = starter.start(args);

  new sec.Starter().start(server);
}