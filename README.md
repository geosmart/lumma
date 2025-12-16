<div align="center">
<p align="center">
  <img src="assets/icon/icon.svg" style="width: 50%; height: auto;">
</p>

<!-- Keep these links. Translations will automatically update with the README. -->
[English](https://www.readme-i18n.com/geosmart/lumma?lang=en) |
[Español](https://www.readme-i18n.com/geosmart/lumma?lang=es) |
[Deutsch](https://www.readme-i18n.com/geosmart/lumma?lang=de) |
[français](https://www.readme-i18n.com/geosmart/lumma?lang=fr) |
[Português](https://www.readme-i18n.com/geosmart/lumma?lang=pt) |
[Русский](https://www.readme-i18n.com/geosmart/lumma?lang=ru) |
[日本語](https://www.readme-i18n.com/geosmart/lumma?lang=ja) |
[한국어](https://www.readme-i18n.com/geosmart/lumma?lang=ko)

</div>

---

# Lumma: AI原生的问答式日记应用

<div align="center">
  <strong>日有所记，问有所思；心有所感，自得其解。</strong>
</div>

> 我热爱记录生活,知识库用的是Obsidian,但android的Obsidian的体验不佳,AI 插件都太重,于是我开发了Lumma这款日记App用来记录.
> android端记是以markdown形式存储在本地,可通过webdav/obsidian插件同步到服务器,然后pc端再同步.

## 功能截图

<div align="center">
  <img src="docs/screenshots/v1.0.0/home.jpg" width="200">
  <img src="docs/screenshots/v1.0.0/chat.jpg" width="200">
  <img src="docs/screenshots/v1.0.0/summary.jpg" width="200">
  <img src="docs/screenshots/v1.0.0/diary_detail.jpg" width="200">
</div>
<div align="center">
  <img src="docs/screenshots/v1.0.0/diary_list.jpg" width="200">
  <img src="docs/screenshots/v1.0.0/diary_mode.jpg" width="200">
  <img src="docs/screenshots/v1.0.0/setting_llm.jpg" width="200">
  <img src="docs/screenshots/v1.0.0/setting_prompt.jpg" width="200">
</div>
<div align="center">
  <img src="docs/screenshots/v1.0.0/summary_prompt.jpg" width="200">
  <img src="docs/screenshots/v1.0.0/setting_qa.jpg" width="200">
  <img src="docs/screenshots/v1.0.0/sync.jpg" width="200">
  <img src="docs/screenshots/v1.0.0/theme.jpg" width="200">
</div>

## 使用方式
我目前的使用方式如下：
1. 手机端在`Lumma`通过`微信语音输入`记录日记内容；
2. 基于`Webdav`插件或`Obsidian客户端`同步到云端；
3. 在`Obsidian电脑端`同步Lumma的日记内容；
4. 周总结按标签汇总统计日记内容

## 核心功能

### 日记模式

- **时间线叙事（Q&A）**：不依赖AI,随时记录
- **AI聊天（Chat）**：像朋友一样对话，与 AI 自由交流内心感受

### AI能力

- 支持多种主流大语言模型（LLM）接入
- 自动生成问答式日记与摘要
- 智能提取标题与分类标签
- 支持自定义提示词和对话风格

### 数据同步
- 所有日记本地持久化为 Markdown 格式
- 支持 WebDAV 云端同步
- 支持通过 Advanced URI 触发 Obsidian 自动同步

