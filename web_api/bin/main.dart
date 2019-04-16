import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:web_api/web_api.dart';

Future main() async {
  Logger.root.level = Level.ALL;

  var app = new Application<WebApi>()
    ..options.configurationFilePath = "config.yaml"
    ..options.port = 8282;
  await app.start();
}
