import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';

String mapToYaml(Map data, {int indent = 0}) {
  final buffer = StringBuffer();
  final spaces = '  ' * indent;
  data.forEach((key, value) {
    if (value is Map) {
      buffer.writeln('$spaces$key:');
      buffer.write(mapToYaml(value, indent: indent + 1));
    } else if (value is List) {
      buffer.writeln('$spaces$key:');
      for (var item in value) {
        if (item is Map) {
          buffer.write('$spaces  - ');
          buffer.write(mapToYaml(item, indent: indent + 2));
        } else {
          buffer.writeln('$spaces  - $item');
        }
      }
    } else {
      buffer.writeln('$spaces$key: $value');
    }
  });
  return buffer.toString();
}
