//
// Contains test for global functions with gradual security typing annotations
//

import 'package:secdart_analyzer/src/helpers/resource_helper.dart';
import 'package:test/test.dart';
import 'test-helpers.dart';


void main() {
  ResourceHelper helper = new ResourceHelper();

  group('Gradual function:', () {

    var program1 =
    '''
    int foo (@high int a1) {
      @low var a = a1;
      return 1;
    }
    ''';

    var program2 =
    '''
    int foo (@high int a1) {
      @high var a = a1;
      return 1;
    }
    ''';

    var program3 =
    '''
    int foo (int a1) {
      @low var a = a1;
      return 1;
    }
    ''';
    var program4 =
    '''int foo (int a1) {
      var a = a1;
      return 1;
    }
    ''';

    setUp(() {

    });
    test('Explicit flow', () {
      var source = helper.newSource("/test.dart",program1);
      expect(typeCheckSecurityForSource(source),isFalse);
    });


    test('Rigth flow', () {

      var source = helper.newSource("/test.dart",program2);
      expect(typeCheckSecurityForSource(source),isTrue);
    });

    test('Rigth flow 2', () {

      var source = helper.newSource("/test.dart",program3);
      expect(typeCheckSecurityForSource(source),isTrue);
    });

    test('Rigth flow 3', () {

      var source = helper.newSource("/test.dart",program4);
      expect(typeCheckSecurityForSource(source),isTrue);
    });

  });
}