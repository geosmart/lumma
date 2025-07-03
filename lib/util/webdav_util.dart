import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WebdavUtil {
  static Future<bool> testConnection({
    required String webdavUrl,
    required String username,
    required String password,
    required String remoteDir,
  }) async {
    try {
      final uri = Uri.parse(webdavUrl + (remoteDir.endsWith('/') ? remoteDir : '$remoteDir/'));
      final auth = base64Encode(utf8.encode('$username:$password'));
      print('=== WebDAV 连接测试 ===');
      print('请求方法: PROPFIND');
      print('请求 URL: $uri');
      final request = http.Request('PROPFIND', uri)
        ..headers.addAll({
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/xml',
          'Depth': '0',
        })
        ..body = '''<?xml version="1.0" encoding="utf-8" ?>\n<D:propfind xmlns:D="DAV:">\n  <D:prop>\n    <D:displayname/>\n  </D:prop>\n</D:propfind>''';
      final response = await http.Client().send(request);
      print('响应状态码: ${response.statusCode}');
      return response.statusCode == 207 || response.statusCode == 200;
    } catch (e, stackTrace) {
      print('WebDAV 连接测试异常: $e\n$stackTrace');
      return false;
    }
  }

  static Future<bool> downloadDirectory({
    required String webdavUrl,
    required String username,
    required String password,
    required String remoteDir,
    required String localDir,
    void Function(int current, int total, String filePath)? onProgress,
  }) async {
    // ...直接复制SyncService._downloadWebdavDirectory内容，去掉SyncService依赖...
    try {
      final uri = Uri.parse(webdavUrl + (remoteDir.endsWith('/') ? remoteDir : '$remoteDir/'));
      final auth = base64Encode(utf8.encode('$username:$password'));
      print('=== WebDAV PROPFIND 请求调试信息 ===');
      print('请求方法: PROPFIND');
      print('请求 URL: $uri');
      print('远程目录: $remoteDir');
      print('本地目录: $localDir');
      final request = http.Request('PROPFIND', uri)
        ..headers.addAll({
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/xml',
          'Depth': '1',
        })
        ..body = '''<?xml version="1.0" encoding="utf-8" ?>\n<D:propfind xmlns:D="DAV:">\n  <D:prop>\n    <D:displayname/>\n    <D:getcontentlength/>\n    <D:getcontenttype/>\n    <D:resourcetype/>\n  </D:prop>\n</D:propfind>''';
      final response = await http.Client().send(request);
      print('响应状态码: ${response.statusCode}');
      if (response.statusCode != 207) {
        print('WebDAV PROPFIND 请求失败: ${response.statusCode}');
        return false;
      }
      final responseBody = await response.stream.bytesToString();
      print('响应体长度: ${responseBody.length} 字符');
      print('响应体内容: $responseBody');
      print('=== WebDAV PROPFIND 请求调试信息结束 ===');
      final files = _parseWebdavResponseWithModified(responseBody, remoteDir);
      print('解析到 ${files.length} 个文件/目录:');
      for (final file in files) {
        print('  ${file['isFile'] ? '文件' : '目录'}: ${file['name']} (路径: ${file['path']})');
      }
      final localDirectory = Directory(localDir);
      if (await localDirectory.exists()) {
        await localDirectory.delete(recursive: true);
      }
      await localDirectory.create(recursive: true);
      int current = 0;
      final total = files.where((f) => f['isFile'] == true).length;
      for (final file in files) {
        if (file['isFile'] == true) {
          current++;
          if (onProgress != null) onProgress(current, total, file['path']);
          final success = await downloadFile(
            webdavUrl: webdavUrl,
            username: username,
            password: password,
            remotePath: file['path'],
            localPath: '$localDir/${file['name']}',
          );
          if (!success) {
            print('下载文件失败: ${file['path']}');
            return false;
          }
        }
      }
      return true;
    } catch (e, stackTrace) {
      print('下载 WebDAV 目录异常: $e\n$stackTrace');
      return false;
    }
  }

  static Future<bool> downloadFile({
    required String webdavUrl,
    required String username,
    required String password,
    required String remotePath,
    required String localPath,
  }) async {
    try {
      final uri = Uri.parse('$webdavUrl$remotePath');
      final auth = base64Encode(utf8.encode('$username:$password'));
      print('=== WebDAV 文件下载请求调试信息 ===');
      print('请求方法: GET');
      print('请求 URL: $uri');
      print('远程路径: $remotePath');
      print('本地路径: $localPath');
      final response = await http.get(uri, headers: {
        'Authorization': 'Basic $auth',
      });
      print('响应状态码: ${response.statusCode}');
      print('响应体长度: ${response.bodyBytes.length} 字节');
      if (response.statusCode == 200) {
        final file = File(localPath);
        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        print('下载文件成功: $remotePath -> $localPath');
        print('=== WebDAV 文件下载请求调试信息结束 ===');
        return true;
      } else {
        print('下载文件失败: $remotePath, 状态码: ${response.statusCode}');
        print('响应内容: ${response.body}');
        print('=== WebDAV 文件下载请求调试信息结束 ===');
        return false;
      }
    } catch (e, stackTrace) {
      print('下载文件异常: $remotePath, 错误: $e\n$stackTrace');
      return false;
    }
  }

  static Future<bool> uploadDirectory({
    required String webdavUrl,
    required String username,
    required String password,
    required String remoteDir,
    required String localDir,
    void Function(int current, int total, String filePath)? onProgress,
  }) async {
    try {
      final dir = Directory(localDir);
      if (!await dir.exists()) {
        print('本地日记目录不存在: $localDir');
        return false;
      }
      final allEntities = await dir.list(recursive: true, followLinks: false).toList();
      final files = allEntities.whereType<File>().cast<File>().toList();
      int current = 0;
      final total = files.length;
      for (final entity in files) {
        current++;
        if (onProgress != null) onProgress(current, total, entity.path);
        final relativePath = entity.path.substring(localDir.length).replaceAll('\\', '/');
        final remotePath = (remoteDir.endsWith('/') ? remoteDir : '$remoteDir/') + relativePath.replaceFirst('/', '');
        final uploadSuccess = await uploadFile(
          webdavUrl: webdavUrl,
          username: username,
          password: password,
          remotePath: remotePath,
          file: entity,
        );
        if (!uploadSuccess) {
          print('上传文件失败: $remotePath');
          return false;
        }
      }
      print('本地目录上传完成');
      return true;
    } catch (e, stackTrace) {
      print('上传本地目录异常: $e\n$stackTrace');
      return false;
    }
  }

  static Future<bool> uploadFile({
    required String webdavUrl,
    required String username,
    required String password,
    required String remotePath,
    required File file,
  }) async {
    try {
      final uri = Uri.parse('$webdavUrl$remotePath');
      final auth = base64Encode(utf8.encode('$username:$password'));
      final bytes = await file.readAsBytes();
      print('=== WebDAV 文件上传请求调试信息 ===');
      print('请求方法: PUT');
      print('请求 URL: $uri');
      print('上传文件: ${file.path} -> $remotePath');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Basic $auth',
        },
        body: bytes,
      );
      print('响应状态码: ${response.statusCode}');
      if (response.statusCode == 201 || response.statusCode == 200 || response.statusCode == 204) {
        print('上传成功: $remotePath');
        print('=== WebDAV 文件上传请求调试信息结束 ===');
        return true;
      } else {
        print('上传失败: $remotePath, 状态码: ${response.statusCode}');
        print('响应内容: ${response.body}');
        print('=== WebDAV 文件上传请求调试信息结束 ===');
        return false;
      }
    } catch (e, stackTrace) {
      print('上传文件异常: $remotePath, 错误: $e\n$stackTrace');
      return false;
    }
  }

  // 获取文件的最后修改时间
  static Future<DateTime?> getRemoteFileLastModified({
    required String webdavUrl,
    required String username,
    required String password,
    required String remotePath,
  }) async {
    try {
      final uri = Uri.parse('$webdavUrl$remotePath');
      final auth = base64Encode(utf8.encode('$username:$password'));

      final request = http.Request('PROPFIND', uri)
        ..headers.addAll({
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/xml',
          'Depth': '0',
        })
        ..body = '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:getlastmodified/>
  </D:prop>
</D:propfind>''';

      final response = await http.Client().send(request);
      if (response.statusCode == 207) {
        final responseBody = await response.stream.bytesToString();
        // 解析 XML 获取最后修改时间
        final lastModifiedMatch = RegExp(r'<D:getlastmodified[^>]*>([^<]+)</D:getlastmodified>').firstMatch(responseBody);
        if (lastModifiedMatch != null) {
          try {
            return DateTime.parse(lastModifiedMatch.group(1)!);
          } catch (e) {
            // 尝试 HTTP 日期格式解析
            return HttpDate.parse(lastModifiedMatch.group(1)!);
          }
        }
      }
      return null;
    } catch (e) {
      print('获取远程文件修改时间异常: $remotePath, 错误: $e');
      return null;
    }
  }

  // 增量上传目录（只上传有变动的文件）
  static Future<bool> uploadDirectoryIncremental({
    required String webdavUrl,
    required String username,
    required String password,
    required String remoteDir,
    required String localDir,
    void Function(int current, int total, String filePath)? onProgress,
  }) async {
    try {
      final dir = Directory(localDir);
      if (!await dir.exists()) {
        print('本地日记目录不存在: $localDir');
        return false;
      }
      final allEntities = await dir.list(recursive: true, followLinks: false).toList();
      final files = allEntities.whereType<File>().cast<File>().toList();

      // 筛选需要上传的文件
      List<File> filesToUpload = [];
      for (final file in files) {
        final relativePath = file.path.substring(localDir.length).replaceAll('\\', '/');
        final remotePath = (remoteDir.endsWith('/') ? remoteDir : '$remoteDir/') + relativePath.replaceFirst('/', '');

        // 获取本地文件修改时间
        final localModified = await file.lastModified();

        // 获取远程文件修改时间
        final remoteModified = await getRemoteFileLastModified(
          webdavUrl: webdavUrl,
          username: username,
          password: password,
          remotePath: remotePath,
        );

        // 如果远程文件不存在或本地文件更新，则需要上传
        if (remoteModified == null || localModified.isAfter(remoteModified)) {
          filesToUpload.add(file);
          print('需要上传: $relativePath (本地: $localModified, 远程: $remoteModified)');
        } else {
          print('跳过上传: $relativePath (本地文件未变更)');
        }
      }

      int current = 0;
      final total = filesToUpload.length;
      print('共需上传 $total 个文件');

      for (final entity in filesToUpload) {
        current++;
        if (onProgress != null) onProgress(current, total, entity.path);
        final relativePath = entity.path.substring(localDir.length).replaceAll('\\', '/');
        final remotePath = (remoteDir.endsWith('/') ? remoteDir : '$remoteDir/') + relativePath.replaceFirst('/', '');
        final uploadSuccess = await uploadFile(
          webdavUrl: webdavUrl,
          username: username,
          password: password,
          remotePath: remotePath,
          file: entity,
        );
        if (!uploadSuccess) {
          print('上传文件失败: $remotePath');
          return false;
        }
      }
      print('增量上传完成，共上传 $total 个文件');
      return true;
    } catch (e, stackTrace) {
      print('增量上传目录异常: $e\n$stackTrace');
      return false;
    }
  }

  // 增量下载目录（只下载有变动的文件）
  static Future<bool> downloadDirectoryIncremental({
    required String webdavUrl,
    required String username,
    required String password,
    required String remoteDir,
    required String localDir,
    void Function(int current, int total, String filePath)? onProgress,
  }) async {
    try {
      final uri = Uri.parse(webdavUrl + (remoteDir.endsWith('/') ? remoteDir : '$remoteDir/'));
      final auth = base64Encode(utf8.encode('$username:$password'));

      final request = http.Request('PROPFIND', uri)
        ..headers.addAll({
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/xml',
          'Depth': '1',
        })
        ..body = '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
    <D:getcontentlength/>
    <D:getcontenttype/>
    <D:resourcetype/>
    <D:getlastmodified/>
  </D:prop>
</D:propfind>''';

      final response = await http.Client().send(request);
      if (response.statusCode != 207) {
        print('WebDAV PROPFIND 请求失败: ${response.statusCode}');
        return false;
      }

      final responseBody = await response.stream.bytesToString();
      final files = _parseWebdavResponseWithModified(responseBody, remoteDir);

      // 确保本地目录存在
      final localDirectory = Directory(localDir);
      if (!await localDirectory.exists()) {
        await localDirectory.create(recursive: true);
      }

      // 筛选需要下载的文件
      List<Map<String, dynamic>> filesToDownload = [];
      for (final file in files) {
        if (file['isFile'] == true) {
          final localPath = '$localDir/${file['name']}';
          final localFile = File(localPath);

          if (!await localFile.exists()) {
            // 本地文件不存在，需要下载
            filesToDownload.add(file);
            print('需要下载: ${file['name']} (本地文件不存在)');
          } else {
            // 比较修改时间
            final localModified = await localFile.lastModified();
            final remoteModified = file['lastModified'] as DateTime?;

            if (remoteModified != null && remoteModified.isAfter(localModified)) {
              filesToDownload.add(file);
              print('需要下载: ${file['name']} (远程文件更新)');
            } else {
              print('跳过下载: ${file['name']} (本地文件是最新的)');
            }
          }
        }
      }

      int current = 0;
      final total = filesToDownload.length;
      print('共需下载 $total 个文件');

      for (final file in filesToDownload) {
        current++;
        if (onProgress != null) onProgress(current, total, file['path']);
        final success = await downloadFile(
          webdavUrl: webdavUrl,
          username: username,
          password: password,
          remotePath: file['path'],
          localPath: '$localDir/${file['name']}',
        );
        if (!success) {
          print('下载文件失败: ${file['path']}');
          return false;
        }
      }

      print('增量下载完成，共下载 $total 个文件');
      return true;
    } catch (e, stackTrace) {
      print('增量下载 WebDAV 目录异常: $e\n$stackTrace');
      return false;
    }
  }

  // 解析 WebDAV PROPFIND 响应，包含修改时间
  static List<Map<String, dynamic>> _parseWebdavResponseWithModified(String xmlResponse, String baseDir) {
    final files = <Map<String, dynamic>>[];
    try {
      final lines = xmlResponse.split('\n');
      String? currentPath;
      bool isCollection = false;
      DateTime? lastModified;

      for (final line in lines) {
        final trimmed = line.trim();

        if (trimmed.contains('<D:href>') && trimmed.contains('</D:href>')) {
          final start = trimmed.indexOf('<D:href>') + 8;
          final end = trimmed.indexOf('</D:href>');
          currentPath = trimmed.substring(start, end);
          if (currentPath.startsWith('/')) {
            currentPath = currentPath.substring(1);
          }
          isCollection = false;
          lastModified = null;
        }

        if (trimmed.contains('<D:collection/>')) {
          isCollection = true;
        }

        if (trimmed.contains('<D:getlastmodified>') && trimmed.contains('</D:getlastmodified>')) {
          final start = trimmed.indexOf('<D:getlastmodified>') + 20;
          final end = trimmed.indexOf('</D:getlastmodified>');
          final dateStr = trimmed.substring(start, end);
          try {
            lastModified = DateTime.parse(dateStr);
          } catch (e) {
            try {
              lastModified = HttpDate.parse(dateStr);
            } catch (e2) {
              print('解析修改时间失败: $dateStr');
            }
          }
        }

        if (trimmed.contains('</D:response>') && currentPath != null) {
          if (currentPath != baseDir.replaceAll('/', '') &&
              currentPath != baseDir.replaceFirst('/', '') &&
              currentPath.isNotEmpty) {
            final fileName = currentPath.split('/').last;
            if (fileName.isNotEmpty) {
              files.add({
                'name': fileName,
                'path': '/$currentPath',
                'isFile': !isCollection,
                'lastModified': lastModified,
              });
            }
          }
          currentPath = null;
        }
      }
    } catch (e) {
      print('解析 WebDAV 响应异常: $e');
    }
    return files;
  }
}
