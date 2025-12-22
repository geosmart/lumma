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
      final uri = Uri.parse(buildWebdavFileUrl(webdavUrl, remoteDir));
      final auth = base64Encode(utf8.encode('$username:$password'));
      print('=== WebDAV 连接测试 ===');
      print('请求方法: PROPFIND');
      print('请求 URL: $uri');
      final request = http.Request('PROPFIND', uri)
        ..headers.addAll({'Authorization': 'Basic $auth', 'Content-Type': 'application/xml', 'Depth': '0'})
        ..body =
            '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
  </D:prop>
</D:propfind>''';
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
      final uri = Uri.parse(buildWebdavFileUrl(webdavUrl, remoteDir));
      final auth = base64Encode(utf8.encode('$username:$password'));
      print('=== WebDAV PROPFIND 请求调试信息 ===');
      print('请求方法: PROPFIND');
      print('请求 URL: $uri');
      print('远程目录: $remoteDir');
      print('本地目录: $localDir');
      final request = http.Request('PROPFIND', uri)
        ..headers.addAll({'Authorization': 'Basic $auth', 'Content-Type': 'application/xml', 'Depth': '1'})
        ..body =
            '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
    <D:getcontentlength/>
    <D:getcontenttype/>
    <D:resourcetype/>
  </D:prop>
</D:propfind>''';
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

  // 公共方法：拼接 WebDAV 文件 URL，自动处理斜杠
  static String buildWebdavFileUrl(String webdavUrl, String remotePath) {
  // 去掉 remotePath 开头所有 /
  String path = remotePath;
  while (path.startsWith('/')) {
    path = path.substring(1);
  }
  // 去掉 remotePath 结尾所有 /
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  // 保证 webdavUrl 结尾有且只有一个斜杠
  String base = webdavUrl.endsWith('/') ? webdavUrl : '$webdavUrl/';
  return base + path;
  }

  static Future<bool> downloadFile({
    required String webdavUrl,
    required String username,
    required String password,
    required String remotePath,
    required String localPath,
  }) async {
    try {
      // 使用公共方法拼接 URL
      final url = buildWebdavFileUrl(webdavUrl, remotePath);
      final uri = Uri.parse(url);
      final auth = base64Encode(utf8.encode('$username:$password'));
      print('=== WebDAV 文件下载请求调试信息 ===');
      print('请求方法: GET');
      print('请求 URL: $uri');
      print('远程路径: $remotePath');
      print('本地路径: $localPath');
      final response = await http.get(uri, headers: {'Authorization': 'Basic $auth'});
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
      // 使用公共方法拼接 URL
      final url = buildWebdavFileUrl(webdavUrl, remotePath);
      final uri = Uri.parse(url);
      final auth = base64Encode(utf8.encode('$username:$password'));
      final bytes = await file.readAsBytes();
      print('上传文件: ${file.path} -> $remotePath');
      final response = await http.put(uri, headers: {'Authorization': 'Basic $auth'}, body: bytes);
      if (response.statusCode == 201 || response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('上传失败: $remotePath, 状态码: ${response.statusCode}');
        print('响应内容: ${response.body}');
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
      // 使用公共方法拼接 URL
      final url = buildWebdavFileUrl(webdavUrl, remotePath);
      final uri = Uri.parse(url);
      final auth = base64Encode(utf8.encode('$username:$password'));

      final request = http.Request('PROPFIND', uri)
        ..headers.addAll({'Authorization': 'Basic $auth', 'Content-Type': 'application/xml', 'Depth': '0'})
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
        final lastModifiedMatch = RegExp(
          r'<D:getlastmodified[^>]*>([^<]+)</D:getlastmodified>',
        ).firstMatch(responseBody);
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
        print('本地工作目录不存在: $localDir');
        return false;
      }
      final allEntities = await dir.list(recursive: true, followLinks: false).toList();
      // 先收集所有本地目录并排序（父目录优先）
      final localDirsList = allEntities.whereType<Directory>().map((entity) {
        return entity.path.substring(localDir.length).replaceAll('\\', '/');
      }).toList();
      localDirsList.sort((a, b) => a.split('/').length.compareTo(b.split('/').length));
      // 依次创建远程目录（父目录优先）
      for (final relativePath in localDirsList) {
        if (relativePath.isEmpty) continue;
        final remotePath = (remoteDir.endsWith('/') ? remoteDir : '$remoteDir/') + relativePath.replaceFirst('/', '');
        print('[增量目录同步] 创建远程目录: $remotePath');
        final created = await createDirectory(
          webdavUrl: webdavUrl,
          username: username,
          password: password,
          remotePath: remotePath,
        );
        if (created) {
          print('[增量目录同步] 成功: $remotePath');
        } else {
          print('[增量目录同步] 失败: $remotePath');
          return false;
        }
      }
      // 筛选需要上传的文件
      List<File> filesToUpload = [];
      for (final file in allEntities.whereType<File>()) {
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
        if (remoteModified == null) {
          print('[同步] 新文件: $relativePath (本地: $localModified, 远程: 无)');
          filesToUpload.add(file);
        } else if (localModified.isAfter(remoteModified)) {
          print('[同步] 已变更: $relativePath (本地: $localModified, 远程: $remoteModified)');
          filesToUpload.add(file);
        } else {
          print('[同步] 无变化: $relativePath (本地: $localModified, 远程: $remoteModified)');
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
      print('=== WebDAV 增量下载目录调试信息 ===');
      print('请求方法: PROPFIND');
      print('远程目录: $remoteDir');
      print('本地目录: $localDir');
      // 使用公共方法拼接 URL
      final uriStr = buildWebdavFileUrl(webdavUrl, remoteDir);
      print('实际请求 URL: $uriStr');
      final uri = Uri.parse(uriStr);
      final auth = base64Encode(utf8.encode('$username:$password'));

      final request = http.Request('PROPFIND', uri)
        ..headers.addAll({'Authorization': 'Basic $auth', 'Content-Type': 'application/xml', 'Depth': 'infinity'})
        ..body =
            '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
    <D:getcontentlength/>
    <D:getcontenttype/>
    <D:resourcetype/>
    <D:getlastmodified/>
  </D:prop>
</D:propfind>''';

      print('发送 PROPFIND 请求...');
      final response = await http.Client().send(request);
      print('响应状态码: ${response.statusCode}');
      if (response.statusCode != 207) {
        print('WebDAV PROPFIND 请求失败: ${response.statusCode}');
        return false;
      }

      final responseBody = await response.stream.bytesToString();
      print('响应体长度: ${responseBody.length} 字符');
      print('响应体内容（前500字符）: ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}');
      print('=== WebDAV PROPFIND 请求调试信息结束 ===');
      final files = _parseWebdavResponseWithModified(responseBody, remoteDir);
      print('webdav解析到 ${files.length} 个文件/目录:');
      for (final file in files) {
        print('  ${file['isFile'] ? '文件' : '目录'}: ${file['name']} (路径: ${file['path']})');
      }

      // 确保本地目录存在
      final localDirectory = Directory(localDir);
      if (!await localDirectory.exists()) {
        await localDirectory.create(recursive: true);
        print('本地目录不存在，已创建: $localDir');
      }

      // 筛选需要下载的文件
      List<Map<String, dynamic>> filesToDownload = [];
      for (final file in files) {
        if (file['isFile'] == true) {
          final localPath = '$localDir/${file['name']}';
          final localFile = File(localPath);

          if (!await localFile.exists()) {
            filesToDownload.add(file);
            print('[增量下载] 需要下载: ${file['name']} (本地文件不存在)');
          } else {
            final localModified = await localFile.lastModified();
            final remoteModified = file['lastModified'] as DateTime?;

            if (remoteModified != null && remoteModified.isAfter(localModified)) {
              filesToDownload.add(file);
              print('[增量下载] 需要下载: ${file['name']} (远程文件更新, 本地: $localModified, 远程: $remoteModified)');
            } else {
              print('[增量下载] 跳过下载: ${file['name']} (本地文件是最新的, 本地: $localModified, 远程: $remoteModified)');
            }
          }
        }
      }

      int current = 0;
      final total = filesToDownload.length;
      print('共需下载 $total 个文件');

      for (final file in filesToDownload) {
        current++;
        print('[增量下载] 开始下载: ${file['name']} (路径: ${file['path']})');
        if (onProgress != null) onProgress(current, total, file['path']);
        final success = await downloadFile(
          webdavUrl: webdavUrl,
          username: username,
          password: password,
          remotePath: file['path'],
          localPath: '$localDir/${file['name']}',
        );
        if (!success) {
          print('[增量下载] 下载文件失败: ${file['path']}');
          return false;
        } else {
          print('[增量下载] 下载文件成功: ${file['path']}');
        }
      }

      print('增量下载完成，共下载 $total 个文件');
      return true;
    } catch (e, stackTrace) {
      print('增量下载 WebDAV 目录异常: $e\n$stackTrace');
      return false;
    }
  }

  static Future<bool> createDirectory({
    required String webdavUrl,
    required String username,
    required String password,
    required String remotePath,
  }) async {
    try {
      // 使用公共方法拼接 URL
      final url = buildWebdavFileUrl(webdavUrl, remotePath);
      final uri = Uri.parse(url);
      final auth = base64Encode(utf8.encode('$username:$password'));
      final response = http.Request('MKCOL', uri)..headers.addAll({'Authorization': 'Basic $auth'});
      final streamedResponse = await http.Client().send(response);
      // MKCOL: 201 Created 或 405 Method Not Allowed（已存在）视为成功
      if (streamedResponse.statusCode == 201 || streamedResponse.statusCode == 405) {
        return true;
      } else {
        print('MKCOL失败: $remotePath 状态码: ${streamedResponse.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      print('MKCOL异常: $e\n$stackTrace');
      return false;
    }
  }

  // 列出远程目录结构（只返回目录路径列表）
  static Future<List<String>> listRemoteDirectories({
    required String webdavUrl,
    required String username,
    required String password,
    required String remoteDir,
  }) async {
    final uri = Uri.parse(webdavUrl + (remoteDir.endsWith('/') ? remoteDir : '$remoteDir/'));
    final auth = base64Encode(utf8.encode('$username:$password'));
    final request = http.Request('PROPFIND', uri)
      ..headers.addAll({'Authorization': 'Basic $auth', 'Content-Type': 'application/xml', 'Depth': '1'})
      ..body =
          '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:resourcetype/>
  </D:prop>
</D:propfind>''';
    final response = await http.Client().send(request);
    if (response.statusCode != 207) return [];
    final responseBody = await response.stream.bytesToString();
    // 解析所有目录路径
    final dirMatches = RegExp(
      r'<D:response>[\s\S]*?<D:resourcetype>[\s\S]*?<D:collection/>[\s\S]*?<D:href>(.*?)<\/D:href>',
    ).allMatches(responseBody);
    final dirs = dirMatches
        .map((m) {
          final href = m.group(1) ?? '';
          // 去除域名和 remoteDir 前缀
          final uri = Uri.parse(href);
          return uri.path;
        })
        .where(
          (path) => path != '/' && path != remoteDir && path != (remoteDir.endsWith('/') ? remoteDir : '$remoteDir/'),
        )
        .toList();
    return dirs;
  }

  // 删除远程目录（WebDAV DELETE 方法）
  static Future<bool> deleteDirectory({
    required String webdavUrl,
    required String username,
    required String password,
    required String remotePath,
  }) async {
    // 使用公共方法拼接 URL
    final url = buildWebdavFileUrl(webdavUrl, remotePath);
    final uri = Uri.parse(url);
    final auth = base64Encode(utf8.encode('$username:$password'));
    final response = await http.delete(uri, headers: {'Authorization': 'Basic $auth'});
    return response.statusCode == 204 || response.statusCode == 200 || response.statusCode == 404;
  }

  // 解析 WebDAV PROPFIND 响应，包含修改时间（支持大小写标签）
  static List<Map<String, dynamic>> _parseWebdavResponseWithModified(String xmlResponse, String baseDir) {
    // 兼容 d: 和 D: 标签
    xmlResponse = xmlResponse.replaceAll('<d:', '<D:').replaceAll('</d:', '</D:');
    final files = <Map<String, dynamic>>[];
    try {
      // 提取所有 <D:response>...</D:response>
      final responseMatches = RegExp(r'<D:response>([\s\S]*?)</D:response>').allMatches(xmlResponse);
      for (final match in responseMatches) {
        final response = match.group(1)!;
        // href
        final hrefMatch = RegExp(r'<D:href>(.*?)</D:href>').firstMatch(response);
        if (hrefMatch == null) continue;
        var currentPath = hrefMatch.group(1)!;
        if (currentPath.startsWith('/')) currentPath = currentPath.substring(1);
        // 只过滤掉 baseDir 自身
        final baseDirPath = baseDir.replaceAll(RegExp(r'^/+|/+$'), '');
        if (currentPath == baseDirPath || currentPath == '$baseDirPath/') continue;
        // 判断是否目录
        final isCollection = response.contains('<D:collection/>');
        // 文件名
        final fileName = currentPath.split('/').last;
        if (fileName.isEmpty) continue;
        // 修改时间
        DateTime? lastModified;
        final lastModifiedMatch = RegExp(r'<D:getlastmodified>([^<]+)</D:getlastmodified>').firstMatch(response);
        if (lastModifiedMatch != null) {
          final dateStr = lastModifiedMatch.group(1)!;
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
        files.add({'name': fileName, 'path': '/$currentPath', 'isFile': !isCollection, 'lastModified': lastModified});
      }
    } catch (e) {
      print('解析 WebDAV 响应异常: $e');
    }
    return files;
  }
}
