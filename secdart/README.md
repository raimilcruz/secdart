# Security annotations for Dart
 
SecDart is an ongoing implementation of gradual security typing in Dart.
This package provides Dart annotations that are recognized for the 
SecDart Analyzer. 

We provide annotations for:
-   individual label of a basic security lattice:
    ``
    @bot < @low < @high < @top
    ``

-   function label annotation: ``@latent(<returnLabel>,<pcLabel>)``
-   for the gradual label:``@dyn``


## Usage

A simple example of usage:

    import 'package:secdart/secdart.dart';
    
    @latent("L","L")
    @low int max(@high int a, @high int b){
        //this produce an error since 'a' and 'b' are high confidencial values (@high)
        //and th return label of the function is @low
        return a + b; 

    }



