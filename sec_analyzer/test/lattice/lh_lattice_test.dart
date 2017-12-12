import '../../lib/src/security_label.dart';
import 'package:test/test.dart';

void main() {
  group('Static Flat Lattice tests :', () {
    Map<String, FlatLabel> staticLabels = {
      "bot" : new BotLabel(),
      "low" : new LowLabel(),
      "high" : new HighLabel(),
      "top" : new TopLabel()
    };
    setUp(() {});
    int i = 0;
    staticLabels.forEach((key, value) {
      int j = 0;
      staticLabels.forEach((key2, value2) {
        if (j >= i) {
          test(key + " < " + key2, () {
            expect(value.lessOrEqThan(value2), isTrue);
            expect(value.canRelabeledTo(value2), isTrue);
          });
        }
        j++;
      });
      i++;
    }
    );
  });

  group('Gradual Flat Lattice tests :', () {
    Map<String, FlatLabel> staticLabels = {
      "bot" : new BotLabel(),
      "low" : new LowLabel(),
      "high" : new HighLabel(),
      "top" : new TopLabel(),
      "unknown" : new DynamicLabel()
    };
    var unknownLabel = new DynamicLabel();

    setUp(() {});

    //unknown < all
    staticLabels.forEach((key, value) {
      test("unknow" + " < " + key, () {
        expect(unknownLabel.lessOrEqThan(value), isTrue);
        expect(unknownLabel.canRelabeledTo(value), isTrue);
      });
    });

    // all < unknown
    staticLabels.forEach((key, value) {
      test(key + " < " + "unknow" , () {
        expect(value.lessOrEqThan(unknownLabel), isTrue);
        expect(value.canRelabeledTo(unknownLabel), isTrue);
      });
    });
  });
}