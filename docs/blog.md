# Blog 写作

首页导航的 Blog 指向 `/blog/`，文章按年份、日期倒序排列。Blog 和文章页拥有独立的阅读界面，列表顶部可返回 Homepage；文章顶部可返回 Blog。界面为英文，无页头标题或页脚。

每篇文章在 `_blog/` 下拥有独立目录，Markdown 正文和图片放在一起：

```text
_blog/
└── example/
    ├── index.md
    ├── references.md
    └── images/
        └── process.svg
```

新文章建立 `_blog/my-first-note/index.md`；有图片时再创建同级 `images/` 目录。`index.md` 的开头填写：

```yaml
---
layout: post
title: 文章标题
date: 2026-09-18 09:00:00 +0800
categories: [研究笔记]
description: 一两句话的摘要，会显示在列表及文章标题下方。
permalink: /blog/my-first-note/
---
```

在以上信息之后直接写 Markdown 正文。每篇文章的 permalink 应唯一，并以 `/blog/` 开头。中文文章可增加 `lang: zh-CN`。草稿请设置 `published: false`，准备好后移除该字段再发布。

支持标题、引用、列表、表格、代码块、脚注及 MathJax 公式。公式渲染需要访问 MathJax CDN。

每篇文章的图片放在自己的 `images/` 子目录，例如 `_blog/example/images/process.svg`。Markdown 中这样引用：

```liquid
![Description of the figure]({{ page.url | append: 'images/process.svg' | relative_url }})
```

`page.url` 自动对应当前文章网址，所以复制文章目录后不需要逐个修改图片路径；`relative_url` 也兼容子路径部署。需要图注时，可以参考使用示例中的 `<figure>` 写法。

目录名称必须与 permalink 的最后一段一致，例如目录 `example/` 对应 `/blog/example/`。图片会发布到 `/blog/example/images/`。不同文章可以使用相同图片文件名，互不冲突。移动或删除一篇文章时，只需要处理整个目录；重命名目录时同步修改 permalink。

站点使用 Jekyll 的 `blog` collection 读取这些目录，列表、RSS 与前后篇导航照常工作。文章通过 `date` 排序，不再需要把日期写入文件名。首次调整 `_config.yml` 后，需要重启本地 Jekyll 服务。

现有的 `/blog/example/` 是唯一一篇使用示例，覆盖公式、代码、图片、表格、脚注和文献引用。可以复制整个 `_blog/example/` 目录来写新文章。示例的 `sitemap: false` 仅用于排除站点地图，文章仍可访问并会出现在 RSS 中；正式发布时可移除这一字段。

本地预览：`bundle exec jekyll serve`，然后访问 `http://127.0.0.1:4000/blog/`。

## 参考文献

文献与文章放在同一目录，正文无需再填写 YAML 文献列表：

```text
_blog/example/
├── index.md
├── references.md
└── images/          # 有图片时再建立
```

### 最简单的引用方式

在 `index.md` 正文写 `[@knuth1984]` 即可：

```markdown
An example of literate programming.[@knuth1984]
A comparison of two papers.[@knuth1984; @shannon1948]
```

也可以使用等价的 Liquid 宏 `{% cite knuth1984 %}`。推荐 `[@key]`，它适合普通 Markdown 编辑器；代码块及行内代码中的这种简写保持原样，不会生成引用。如果需要在文章中展示 Liquid 宏本身，使用 Liquid 的 `raw` 块，避免被提前执行。

### 独立的 references.md

文件不需要 YAML front matter。在 Markdown 中放一个或多个 `bibtex` 代码块，直接粘贴从论文网站导出的 BibTeX：

````markdown
# References

```bibtex
@article{knuth1984,
  author = {Knuth, Donald E.},
  title = {Literate Programming},
  journal = {The Computer Journal},
  year = {1984},
  volume = {27},
  number = {2},
  pages = {97--111},
  doi = {10.1093/comjnl/27.2.97}
}
```
````

代码块之外可以写自己的整理笔记；这些笔记不会放到文章里。`bib` 也可用作代码块的语言名。

### 直接使用 .bib

如果已有 BibTeX 文件，直接保存为同目录的 `references.bib`，不加 Markdown 代码围栏。正文仍然使用同样的 `[@key]`，无需任何额外配置。两个文献文件也可以同时存在，条目会合并，但引用键不能重复。

系统支持常见 BibTeX 条目、嵌套花括号、作者姓名、LaTeX 字符转义与 `@string` 字符串。显示作者、年份、标题、期刊或会议／出版社、卷期页码、DOI 和来源链接；这是本站统一的简洁格式，不是完整的 CSL／BibLaTeX 样式引擎。

文献按正文首次引用的顺序编号。重复引用使用原编号，文末为每次出现生成返回链接；只列出实际引用过的文献。点击引用或返回链接后，目标位置会高亮。脚注 `[^note]` 仍独立编号。

引用键必须以英文字母或数字开头，之后可包含字母、数字、下划线、连字符、点号、冒号、加号或斜杠。键不存在、重复、缺少标题或 BibTeX 格式错误时，构建会报错并指出对应文件。URL 使用完整的 HTTP／HTTPS 地址。

`references.md` 和 `references.bib` 只作为构建输入，不会被列为文章，也不会复制到网站。修改它们会随本地自动构建更新正文。完整例子见 `_blog/example/`。

## 构建与发布

首次使用新增依赖时运行 `bundle install`，再运行 `bundle exec jekyll liveserve --host 127.0.0.1`。新增或修改 `_plugins/` 中的解析代码后需重启服务；日常编辑文章和文献不需要重启。

引用功能由 `_plugins/blog_citations.rb` 在构建时处理，不依赖浏览器 JavaScript。检查命令：

```sh
bundle exec ruby tests/blog_citations_test.rb
bundle exec jekyll build
```

GitHub Pages 默认的分支构建不会加载自定义插件，因此已提供 `.github/workflows/pages.yml`。发布时需要在仓库 **Settings → Pages → Build and deployment → Source** 选择 **GitHub Actions**。随后推送 `main` 或手动运行该工作流即可构建发布；不要使用 `jekyll build --safe`。这些设置尚未在远程仓库修改，工作流也尚未在线运行。
