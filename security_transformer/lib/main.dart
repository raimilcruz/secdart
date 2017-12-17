import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:security_transformer/security_transformer.dart';

Future main() async {
  final barback = new Barback(new MyPackageProvider());
  barback.updateTransformers('security_transformer', [
    [new SecurityTransformer.asPlugin()]
  ]);
  barback.updateSources([new AssetId(package, path)]);
  final assetSet = await barback.getAllAssets();
  for (final asset in assetSet) {
    final content = await asset.readAsString();
    print(content);
  }
}

final package = 'security_transformer';

final path = 'lib/test.dart';

class MyPackageProvider extends PackageProvider {
  @override
  Iterable<String> get packages => [package];

  // TODO: implement packages
  @override
  Future<Asset> getAsset(AssetId id) {
    final asset =
        new Asset.fromFile(new AssetId(package, path), new File(path));
    return new Future<Asset>(() => asset);
  }
}
