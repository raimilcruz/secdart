import 'package:secdart_analyzer_plugin/src/helpers/resource_helper.dart';
import 'package:test/test.dart';
import 'test-helpers.dart';

void main() {
  group('Implicit flow tests:', () {
    ResourceHelper helper = new ResourceHelper();

    setUp(() {
    });

    test('Classes are not supported', () {
      var program =
      '''class A{}
      ''';

      var source = helper.newSource("/test.dart",program);
      expect(containsOnlySupportedFeatures(source),isFalse);

    });
    test('Enums are not supported', () {
      var program =
      '''enum Color {
          red,
          green,
          blue
       }
      ''';

      var source = helper.newSource("/test.dart",program);
      expect(containsOnlySupportedFeatures(source),isFalse);

    });

    test('throw are not supported', () {
      var program =
      '''void A(){
  throw new UnimplementedError();
}
      ''';

      var source = helper.newSource("/test.dart",program);
      expect(containsOnlySupportedFeatures(source),isFalse);

    });

    test('function type alias is not supported', () {
      var program =
      '''typedef int Compare(int a, int b);
      ''';

      var source = helper.newSource("/test.dart",program);
      expect(containsOnlySupportedFeatures(source),isFalse);

    });
  });
}