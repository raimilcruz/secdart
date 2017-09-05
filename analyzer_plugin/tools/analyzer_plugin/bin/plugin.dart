import 'dart:isolate';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/starter.dart';
import 'package:secdart_analyzer_plugin/plugin.dart';

void main(List<String> args, SendPort sendPort) {
  SecDartPlugin plugin = new SecDartPlugin(PhysicalResourceProvider.INSTANCE);
  new ServerPluginStarter(plugin).start(sendPort);
}