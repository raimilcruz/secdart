import 'package:secdart_analyzer_plugin/src/helpers/resource_helper.dart';
import 'package:test/test.dart';
import 'test-helpers.dart';

void main() {
  ResourceHelper helper = new ResourceHelper();

  group('Binary expression tests :', () {

    setUp(() {
    });


    test('Sum bad. Sum produces a high confidential result that will be assigned to a low confidential variable', () {
      var program =
      '''@latent("H","L")
         @high int foo (@high int a1, @low int a2) {
            @low var a = a1 + a2;
            return 1;
          }
      ''';

      var source = helper.newSource("/test.dart",program);
      expect(typeCheckSecurityForSource(source),isFalse);
    });

    test('Sum ok.', () {
      var program =
      '''@latent("L","L")
          @high int foo (@low int a1, @low int a2) {
            @low var a = a2 + a2;
            return 1;
          }
      ''';
      var source = helper.newSource("/test.dart",program);
      expect(typeCheckSecurityForSource(source),isTrue);
    });
  });
}