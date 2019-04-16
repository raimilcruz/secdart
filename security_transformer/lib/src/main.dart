import 'dart:async';
import 'dart:io';

/*
import 'package:barback/barback.dart';
import 'package:dart_style/dart_style.dart';
import 'package:security_transformer/security_transformer.dart';

Future main() async {
  final package = 'security_transformer';
  final sourcePath = 'example/test.dart';
  final targetPath = 'example/generated.dart';
  final runner = new SecurityTransformerRunner();
  final content = await runner.transformAndFormat(package, sourcePath);
  print(content);
  await new File(targetPath).writeAsString(content);
}

class MyPackageProvider extends PackageProvider {
  String package, sourcePath;
  MyPackageProvider(this.package, this.sourcePath);

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

class SecurityTransformerRunner {
  DartFormatter formatter = new DartFormatter();

  Future<String> transform(String package, String sourcePath) async {
    final barBack = new Barback(new MyPackageProvider(package, sourcePath));
    barBack.updateTransformers('security_transformer', [
      [new SecurityTransformer.asPlugin()]
    ]);
    barBack.updateSources([new AssetId(package, sourcePath)]);
    final assetSet = await barBack.getAllAssets();
    final result = <String>[];
    for (final asset in assetSet) {
      result.add(await asset.readAsString());
    }
    assert(result.length == 1);
    return result.first;
  }

  Future<String> transformAndFormat(String package, String sourcePath) async {
    return formatter.format(await transform(package, sourcePath));
  }
}*/
