import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Provides a [Source] from a [String]
 */
class ResourceHelper {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  /**
   * Provide a [Source] from a [String] representing the content of the source.
   */
  Source newSource(String path, [String content = '']) {
    File file = resourceProvider.newFile(path, content);
    return file.createSource();
  }
}
