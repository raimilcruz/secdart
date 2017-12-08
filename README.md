# SecDart
SecDart is an ongoing implementation of gradual security typing for Dart.

## Installation
We will provide three ways to interact with the SecDart's security analysis (currently just 
the first one is available!):
- **Using the online SecDart Pad** at [https://pleiad.cl/secdart/](https://pleiad.cl/secdart/)
- **The SecDart Analyzer CLI**
- **The SecDart Plugin for the Dart Analysis Server.**

### The SecDart Plugin
The plugin is unstable at the current state, but it is possible to see the result
of the security analysis for the supported subset of Dart. The initial tests has been 
done in WebStorm and Intellij.  
1. Download a copy of this repository
2. Update the dependency to the plugin implementation (``secdart_analyzer_plugin``) in 
 the ``/secdart/secdart/tools/analyzer_plugin/pubspec.yaml`` file.
    ```
    dependencies:
      secdart_analyzer_plugin:
        path: <absolute-path-to-the-secdart_analyzer_plugin-plugin-folder>
    ```

3. Create a package to use this plugin and enable the plugin in your ``analysis_option.yaml`` file:
    ```
    analyzer:
      strong-mode: true
      plugins:
          secdart:
            enable: true
    ```

4. Add a reference to the secdart package in your ``pubspec.yaml`` file. The ``secdart`` package
contains the security annotations that area recognized by the analysis:
    ```
    dependencies:
      secdart:
        path: <local-path-to-the-secdart-package>
    ```


  
![SecDart Plugin Preview in WebStorm](/assets/plugin_in_webstorm.gif "Preview gif")


## Documentation
The current implementation and documentation are admittedly limited. However
any update will be placed at 
[https://pleiad.cl/research/software/secdart](https://pleiad.cl/research/software/secdart).

## Acknowledge
To interact with the 
[Analyzer Plugin Framework](https://github.com/dart-lang/sdk/tree/master/pkg/analyzer_plugin) 
we have followed the implementation of 
[Angular Analyzer Plugin](https://github.com/dart-lang/angular_analyzer_plugin). 
We have reused ideas and code from that project.