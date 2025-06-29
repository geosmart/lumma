import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ConfigService {
  static Future<File> getJsonConfigFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }
}
