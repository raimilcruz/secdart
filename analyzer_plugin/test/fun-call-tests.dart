import 'package:test/test.dart';
import 'test-helpers.dart';

void main() {
  ResourceHelper helper = new ResourceHelper();

  group('Function call tests:', () {
    setUp(() {});

    test('Simple call ok', () {
      var program =
      '''@latent("H","H")
@high foo (@high int s) {
  return 1;
}

@latent("H","H")
@high callFoo(){
  foo(5);
}
      ''';

      var source = helper.newSource("/test.dart",program);
      expect(typeCheckSecurityForSource(source),isTrue);
    });

    //TODO: Fix test
/*    test('Simple call bad', () {
      var program =
      '''@latent("H","L")
@high foo (@high int s) {
  return 1;
}

@latent("H","H")
@high callFoo(){
  foo(5);
}
      ''';

      var source = helper.newSource("/test.dart",program);
      expect(typeCheckSecurityForSource(source), isFalse);
    });*/

  });
}
