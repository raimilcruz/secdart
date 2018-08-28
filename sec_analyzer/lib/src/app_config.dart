import 'dart:io';

import 'package:safe_config/safe_config.dart';

class AppConfiguration extends Configuration {
  static AppConfiguration _singleton;

  AppConfiguration._internal(File file) :
        super.fromFile(file);

  AppConfiguration._default() : super();

  int debug;

  bool get isDebug => debug == 1;

  static AppConfiguration defaultConfig(){
    if(_singleton ==null) {
      var file = new File("config.yaml");
      _singleton = file.existsSync()
          ? new AppConfiguration._internal(file)
          : new AppConfiguration._default();
    }
    return _singleton;
  }
}