class FrontmatterService {
  /// 生成 frontmatter 字符串
  static String generate({required DateTime created, required DateTime updated}) {
    final createdStr = created.toIso8601String().substring(0,19);
    final updatedStr = updated.toIso8601String().substring(0,19);
    return '''---\ncreated: ${createdStr.replaceAll(RegExp(r"\.\d+"), '')}\nupdated: ${updatedStr.replaceAll(RegExp(r"\.\d+"), '')}\n---\n''';
  }

  /// 检查并补全 frontmatter，没有则加，有则只更新 updated 字段
  static String upsert(String content, {DateTime? created, required DateTime updated}) {
    final lines = content.split('\n');
    final updatedStr = updated.toIso8601String().substring(0,19).replaceAll(RegExp(r"\.\d+"), '');
    if (lines.isNotEmpty && lines[0].trim() == '---') {
      int endIdx = lines.indexWhere((l) => l.trim() == '---', 1);
      if (endIdx > 0) {
        final front = lines.sublist(0, endIdx+1);
        final body = lines.sublist(endIdx+1).join('\n');
        final updatedFront = front.map((l) => l.startsWith('updated:') ? 'updated: $updatedStr' : l).toList();
        return '${updatedFront.join('\n')}\n$body';
      }
    }
    // 没有 frontmatter，补全
    final createdStr = (created ?? updated).toIso8601String().substring(0,19).replaceAll(RegExp(r"\.\d+"), '');
    return '''---\ncreated: $createdStr\nupdated: $updatedStr\n---\n$content''';
  }
}
