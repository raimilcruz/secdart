import 'dart:io';

import 'package:safe_config/safe_config.dart';

class AppConfiguration extends Configuration {
  static AppConfiguration _singleton;

  AppConfiguration._internal(String fileName) :
        super.fromFile(new File(fileName));

  int debug;

  bool get isDebug => debug == 1;

  static AppConfiguration defaultConfig(){
    if(_singleton ==null)
      _singleton = new AppConfiguration._internal("config.yaml");
    return _singleton;
  }
}