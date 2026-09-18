---
layout: post
title: A writing example
date: 2026-09-18 09:00:00 +0800
categories: [Guide]
description: How to write a post, with working examples of the supported formats.
permalink: /blog/example/
sitemap: false
---
This page is a working example. Copy its folder to start a new post, then replace the text, images, and bibliography.

## 1. Citations

In the article, write `[@knuth1984]` to create a numbered citation. Here is the rendered result.[@knuth1984]

For multiple sources, use `[@knuth1984; @shannon1948]`. Here is that example.[@knuth1984; @shannon1948]

{% raw %}
The equivalent macro is `{% cite knuth1984 %}`.
{% endraw %}
This sentence uses the macro.{% cite knuth1984 %}

References are numbered in order of first appearance. Repeated citations keep the same number, and each has its own return link. Only cited entries appear in the reference list. Citation syntax inside code remains literal: `[@not-a-real-reference]`.

## 2. Footnotes

Write `[^note]` in the text and define the note elsewhere in the file:

```markdown
A sentence with a note.[^note]

[^note]: The note's text.
```

Here is a working footnote.[^note] Click its number to read it, then use the return arrow to come back. The destination is highlighted.

## 3. Create a post

Keep everything for one article in one folder:

```text
_blog/my-post/
├── index.md
├── references.md
└── images/
    └── figure.svg
```

Start `index.md` with this metadata, followed by your Markdown text:

```yaml
---
layout: post
title: My post
date: 2026-09-18 09:00:00 +0800
categories: [Notes]
description: A short description.
permalink: /blog/my-post/
---
```

Match the folder name to the last part of the permalink. Posts are ordered by date. Add `published: false` while writing a draft, then remove it to publish. Images and reference files are optional.

## 4. Text, headings, and lists

Use `##` for a section and `###` for a subsection. Paragraphs are separated by a blank line. Text can be **bold**, *italic*, or `inline code`.

### A subsection

- A short item.
- Another item with a [link to the homepage]({{ '/#about-me' | relative_url }}).

1. Write the content.
2. Preview the page.
3. Publish when ready.

Use `>` at the beginning of a line for a blockquote:

> This is an example blockquote. It is not attributed to a source.

## 5. Equations

Put inline mathematics between dollar signs: `$a^2 + b^2 = c^2$` becomes $a^2 + b^2 = c^2$.

Use double dollar signs for a displayed equation:

```latex
$$
\operatorname{MSE} = \frac{1}{n}\sum_{i=1}^{n}(y_i-\hat{y}_i)^2.
$$
```

$$
\operatorname{MSE} = \frac{1}{n}\sum_{i=1}^{n}(y_i-\hat{y}_i)^2.
$$

MathJax renders the equation when the page loads.

## 6. Code

Use a fenced code block with a language name such as `python`:

```python
def mean_squared_error(actual, predicted):
    if not actual or len(actual) != len(predicted):
        raise ValueError("Expected matching nonempty sequences")
    errors = [(a - p) ** 2 for a, p in zip(actual, predicted)]
    return sum(errors) / len(errors)
```

Long code lines scroll horizontally inside the block.

## 7. Images

Save a figure in this article's `images/` folder. This expression automatically uses the current article URL:

{% raw %}
```liquid
![A description of the figure]({{ page.url | append: 'images/process.svg' | relative_url }})
```
{% endraw %}

For a caption, use `<figure>`, `<img>`, and `<figcaption>` as in this article's source:

<figure>
  <img src="{{ page.url | append: 'images/process.svg' | relative_url }}" alt="A diagram with three boxes: question, method, and open questions" width="900" height="240" loading="lazy">
  <figcaption>Figure 1. An example image and caption.</figcaption>
</figure>

## 8. Tables

Use pipes to separate columns and a row of dashes beneath the header:

```markdown
| File | Purpose |
| --- | --- |
| index.md | Article text |
| references.md | Bibliography |
```

| File | Purpose |
| --- | --- |
| `index.md` | Article text and metadata |
| `references.md` or `references.bib` | Bibliographic records |
| `images/` | This article's figures |

## 9. Reference files

Create `references.md` next to `index.md`. Paste BibTeX entries inside a fenced `bibtex` block:

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

If you already have a `.bib` file, save it as `references.bib` instead, without code fences. No additional configuration is needed.

## 10. Preview

From the project directory, run:

```sh
bundle install
bundle exec jekyll liveserve --host 127.0.0.1
```

Open `/blog/` on the local preview. Edits to the article, images, or references are picked up automatically. To check a production build, run `bundle exec jekyll build`.

[^note]: This is a sample footnote. It is separate from the numbered bibliography below.
