# SecDart
SecDart is an ongoing implementation of gradual security typing for Dart.

## Installation
We will provide three ways to interact with the SecDart's security analysis (currently just the first one is available!):
- **Using the online SecDart Pad** at [https://pleiad.cl/secdart/](https://pleiad.cl/secdart/)
- **The SecDart Analyzer CLI**
- **The SecDart Plugin for the Dart Analysis Server.**

### The SecDart Plugin
The plugin is unstable at the current state, but it is possible to see the result
of the security analysis for the supported subset of Dart.

The initial tests has been done in WebStorm. For now to see the plugin working you need to 
download and build this project locally. 
It is expected that the plugin can be loaded automatically by the Analysis Framework 
(once we find out how to do it).

![SecDart Plugin Preview in WebStorm](/assets/plugin_in_webstorm.gif "Preview gif")


## Documentation
The current implementation and documentation are admittedly limited. However
any update will be placed at [https://pleiad.cl/research/software/secdart](https://pleiad.cl/research/software/secdart).

## Acknowledge
This project is a fork of the [Angular Analyzer Plugin](https://github.com/dart-lang/angular_analyzer_plugin). 
Many ideas and code of how to interact with the [Analyzer Plugin
Framework](https://github.com/dart-lang/sdk/tree/master/pkg/analyzer_plugin) has been taken from that project.
