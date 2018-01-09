import 'package:security_transformer/security_transformer.dart';

void main() {
  //create an instance of the security compiler
  final secCompiler = new SecurityCompiler();
  //example of code in SecDart
  final program = '''
       import "package:secdart/secdart.dart";
       @latent("H","L")
       @high int foo (@high int a1, int a2) {
          @low var a = a1 + a2;
          return 1;
        }
    ''';
  //compile the code
  final compiled = secCompiler.compile(program);
  //the result is ready to run.
  print(compiled);
}
