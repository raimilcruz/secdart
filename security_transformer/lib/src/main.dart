import 'dart:async';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:dart_style/dart_style.dart';
import 'package:security_transformer/security_transformer.dart';

Future main() async {
  barBack.updateTransformers('security_transformer', [
    [new SecurityTransformer.asPlugin()]
  ]);
  barBack.updateSources([new AssetId(package, sourcePath)]);
  final assetSet = await barBack.getAllAssets();
  for (final asset in assetSet) {
    final content = formatter.format(await asset.readAsString());
    print(content);
    await new File(targetPath).writeAsString(content);
  }
}

final barBack = new Barback(new MyPackageProvider());

final formatter = new DartFormatter();

final package = 'security_transformer';

final sourcePath = 'example/test.dart';

final targetPath = 'example/generated.dart';

class MyPackageProvider extends PackageProvider {
  @override
  Iterable<String> get packages => [package];

  // TODO: implement packages
  @override
  Future<Asset> getAsset(AssetId id) {
    final asset = new Asset.fromFile(
        new AssetId(package, sourcePath), new File(sourcePath));
    return new Future<Asset>(() => asset);
  }
}
