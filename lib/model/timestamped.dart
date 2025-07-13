// 统一的时间戳基类
abstract class Timestamped {
  DateTime created;
  DateTime updated;

  Timestamped({DateTime? created, DateTime? updated})
    : created = created ?? DateTime.now(),
      updated = updated ?? DateTime.now();
}
