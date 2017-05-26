import 'package:secdart_analyzer_plugin/src/helpers/resource_helper.dart';
import 'package:test/test.dart';
import 'test-helpers.dart';

void main() {
  group('Implicit flow tests:', () {
    ResourceHelper helper = new ResourceHelper();

    setUp(() {
    });

    test('If statement with standard implicit flow ', () {
      var program =
      '''@latent("L","L")
@low foo (@high bool s) {
  @low bool a = false;
  if(s){
    a = true; //Must be rejected (pc here must be H)
  }
  else{
    a = false;
  }
  return 1;
}
      ''';

      var source = helper.newSource("/test.dart",program);
      expect(typeCheckSecurityForSource(source),isFalse);

    });

    test('If statament without implicit flow ', () {
      var program =
      '''@latent("L","L")
@low foo (@low bool s) {
  @low bool a = false;
  if(s){
    a = true; //Must be rejected (pc here must be H)
  }
  else{
    a = false;
  }
  return 1;
}
      ''';

      var source = helper.newSource("/test.dart",program);
      expect(typeCheckSecurityForSource(source),isTrue);
    });
  });
}