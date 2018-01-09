import 'dart:async';

import 'package:barback/barback.dart';
import 'package:security_transformer/security_compiler.dart';

export "security_compiler.dart";

class SecurityTransformer extends Transformer {
  SecurityTransformer.asPlugin();

  @override
  apply(Transform transform) async {
    final secCompiler = new SecurityCompiler();
    final content = await transform.primaryInput.readAsString();
    final newContent = secCompiler.compile(content);

    final id = transform.primaryInput.id;
    transform.addOutput(new Asset.fromString(id, newContent));
  }

  Future<bool> isPrimary(AssetId id) {
    bool isDartFile = id.path.endsWith('.dart');
    bool ownPackageFilter = id.package != 'security_transformer' ||
        id.path == 'example/test.dart' ||
        id.path.startsWith('test/dart_files/sources/');
    return new Future.value(isDartFile && ownPackageFilter);
  }
}
