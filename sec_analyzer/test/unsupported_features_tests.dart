import 'test_helpers.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnsupportedFeaturesTest);
  });
}

@reflectiveTest
class UnsupportedFeaturesTest extends AbstractSecDartTest {
  void test_enumIsNotSupported() {
    var program = '''enum Color {
          red,
          green,
          blue
       }
      ''';
    var source = newSource("/test.dart", program);
    assert(!containsOnlySupportedFeatures(source));
  }

  void test_throwIsNotSupported() {
    var program = '''void A(){
        throw new UnimplementedError();
      }
      ''';
    var source = newSource("/test.dart", program);
    assert(!containsOnlySupportedFeatures(source));
  }
}
