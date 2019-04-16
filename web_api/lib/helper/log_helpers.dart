import 'dart:io';

import 'package:logging/logging.dart';

class FileLogger {
  final String filename;
  File _file;

  FileLogger(this.filename) {
    _file = new File(filename);
  }
  call(LogRecord logRecord) {
    var f = _file.openSync(mode: FileMode.append);
    f.writeStringSync(logRecord.toString() + "\n");
    f.closeSync();
  }
}

class TerminalLogger {
  call(LogRecord record) {
    print("$record ${record.error ?? ""} ${record.stackTrace ?? ""}");
  }
}
