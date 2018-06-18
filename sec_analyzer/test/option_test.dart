import 'package:secdart_analyzer/src/options.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:test/test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SecDartOptionsTest);
    defineReflectiveTests(LatticeOptionTest);
  });
}

@reflectiveTest
class SecDartOptionsTest {
  void test_buildEmpty() {
    final options = new SecDartOptions.defaults();
    expect(options.intervalMode, isFalse);
  }

  void test_buildYaml_defaults() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart:
''');
    expect(options.intervalMode, isFalse);
  }

  void test_buildYaml_defaults2() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    - secdart
''');
    expect(options.intervalMode, isFalse);
  }

  void test_buildYaml_intervals_false() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart:
      intervals: true
''');
    expect(options.intervalMode, isTrue);
  }

  void test_buildYaml_intervals_true() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart:
      intervals: false
''');
    expect(options.intervalMode, isFalse);
  }

  void test_buildYaml_latticeIsNotNull() {
    final options = new SecDartOptions.from('''
analyzer:
  plugins:
    secdart:
      lattice: 'lattice.yaml'
''');
    expect(options.latticePath, "lattice.yaml");
  }
}

@reflectiveTest
class LatticeOptionTest {
  void test_buildYaml_lattice() {
    final lattice = new LatticeFile.from('''
name: AliceBob
elements:
  - B
  - Alice
  - Bob
  - T
order:
  - 'B <= Alice'
  - 'Alice <= Bob'
  - 'Bob <= T'
bottom: B
top: T
''');
    expect(lattice.name, "AliceBob");
    expect(lattice.elements, ["B", "Alice", "Bob", "T"]);
    expect(lattice.order, [
      new LabelOrder("B", "Alice"),
      new LabelOrder("Alice", "Bob"),
      new LabelOrder("Bob", "T")
    ]);
    expect(lattice.top, "T");
    expect(lattice.bottom, "B");
  }

  void test_buildYaml_NoDefinition() {
    final lattice = new LatticeFile.from('''
name: 
elements:
order:
bottom: 
top: 
''');
    expect(lattice.name, isNull);
    expect(lattice.elements, []);
    expect(lattice.order, []);
    expect(lattice.top, isNull);
    expect(lattice.bottom, isNull);
  }

  void test_buildYaml_Empty() {
    final lattice = new LatticeFile.from('''
''');
    expect(lattice.name, isNull);
    expect(lattice.elements, []);
    expect(lattice.order, []);
    expect(lattice.top, isNull);
    expect(lattice.bottom, isNull);
  }

  void test_buildYaml_BadOrder() {
    final lattice = new LatticeFile.from('''
name: AliceBob
elements: 
  - B
  - Alice
  - Bob
#all elements of the list 'order' must have the format 'S <= S'  
order:
  - 'B < Alice'
  - 'Alice <= Bob'
bottom: B
top: Bob
''');
    expect(lattice.name, 'AliceBob');
    expect(lattice.elements, ["B", "Alice", "Bob"]);
    expect(lattice.order, []);
    expect(lattice.top, "Bob");
    expect(lattice.bottom, "B");
  }
}
