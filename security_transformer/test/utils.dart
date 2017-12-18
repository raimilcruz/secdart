import 'dart:async';
import 'dart:io';

Future<List<FileSystemEntity>> dirContents(Directory dir) {
  var files = <FileSystemEntity>[];
  var completer = new Completer();
  var lister = dir.list(recursive: false);
  lister.listen((file) => files.add(file),
      onDone: () => completer.complete(files));
  return completer.future;
}

Future<List<String>> dirContentsPath(String dirPath) async {
  final rawResult = await dirContents(new Directory(dirPath));
  final result = rawResult.map((e) => e.path).toList();
  return result;
}
