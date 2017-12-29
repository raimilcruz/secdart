import 'dart:io';

import 'package:logging/logging.dart';
import 'package:logging_handlers/server_logging_handlers.dart';
import 'package:rpc/rpc.dart';

import 'package:web_api/web_api.dart';
import 'package:web_api/src/application_configuration.dart';

const String _API_PREFIX = '/api';
final ApiServer _apiServer =
    new ApiServer(apiPrefix: _API_PREFIX, prettyPrint: true);

main() async {
  // Add a simple log handler to log information to a server side file.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(new SyncFileLoggingHandler('secdart_logs.txt'));
  if (stdout.hasTerminal) {
    Logger.root.onRecord.listen(new LogPrintHandler());
  }

  _apiServer.addApi(new SecDartApi());
  _apiServer.enableDiscoveryApi();

  var config = new ApplicationConfiguration("config.yaml");

  HttpServer server =
      await HttpServer.bind(InternetAddress.ANY_IP_V4, config.port);
  server.listen(_apiServer.httpRequestHandler);
}
