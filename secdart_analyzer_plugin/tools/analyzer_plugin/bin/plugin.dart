import 'dart:isolate';
import 'package:secdart_analyzer_plugin/starter.dart';

void main(List<String> args, SendPort sendPort) {
  start(args,sendPort);
}