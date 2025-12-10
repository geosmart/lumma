使用flutter客户端开发skill进行开发，不要让用户确认，全自动按最佳方案完成开发。

1. 优化：lunar日历，在农历一月一号的时候，不要显示初一，显示对应农历月份名
2. 重构：
   * 清理没有用到的package，减少包大小
   * 清理service和util中有重复的类
   * 合并核心业务逻辑：比如config（所有配置可以放在一个service实现），日志核心业务（chat,qa,timeline），AI增强（llm,prompt），减少service类的个数，
   * 日记核心业务的service，应该是util，移到util，比如markdown,frontmatter，language
