import '../lib/starter.dart' as sec;
import 'package:analysis_server/starter.dart';

/**
 * Create and run an analysis server with the SecDart plugins.
 */
void main(List<String> args) {
  final starter = new ServerStarter();

  final server = starter.start(args);

  new sec.Starter().start(server);
}