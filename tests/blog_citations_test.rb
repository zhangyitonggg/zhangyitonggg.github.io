# frozen_string_literal: true

require "bundler/setup"
require "jekyll"
require "tmpdir"
require "fileutils"
require_relative "../_plugins/blog_citations"

def assert(condition, message)
  raise message unless condition
end

def rejects(message)
  yield
  raise "Expected an error containing #{message}"
rescue Jekyll::Errors::FatalException => error
  assert(error.message.include?(message), error.message)
end

Dir.mktmpdir("blog-citations-test") do |directory|
  directory = File.realpath(directory)
  bib = <<~'BIB'
    @string{journalname = "Example " # "Journal"}
    @article{alpha,
      author = {Garc{\'i}a, Ana and {Example Lab}},
      title = {{A nested {title}} and \& symbols},
      journal = journalname,
      year = {2024}, volume = {2}, number = {3}, pages = {10--20},
      doi = {https://doi.org/10.1234/example}
    }
    @book{beta, author = {Doe, Jane}, title = {Second title},
      publisher = {Example Press}, year = {2023},
      url = {https://example.org/book?a=1&b=2}}
    @misc{unused, title = {Not cited}}
  BIB
  path = File.join(directory, "references.md")
  File.write(path, "# References\n\n```bibtex\n#{bib}```\n")
  records = BlogCitations.load(directory)
  assert(records["alpha"]["authors"] == "Ana García, Example Lab", "Author/LaTeX conversion")
  assert(records["alpha"]["title"] == "A nested title and & symbols", "Nested BibTeX braces")
  assert(records["alpha"]["venue"] == "Example Journal, 2(3), 10–20", "String expansion/venue")
  assert(records["alpha"]["doi"] == "10.1234/example", "DOI normalization")

  input = '<p>First [@beta], then [@alpha; @beta].</p><pre><code>[@missing]</code></pre><p><code>[@missing]</code></p>'
  html = BlogCitations.render(input, records, "test")
  doc = Nokogiri::HTML.fragment(html)
  assert(doc.css('.blog-citation a').map(&:text) == ['[1]', '[2]', '[1]'], "First-use and repeat numbering")
  assert(doc.css('.blog-references li').size == 2, "Only cited references")
  assert(doc.css('code').all? { |code| code.text == '[@missing]' }, "Code must stay literal")
  ids = doc.css('[id]').map { |node| node['id'] }
  assert(ids.uniq == ids, "Unique citation anchors")
  doc.css('a[href^="#"]').each do |link|
    assert(ids.include?(link['href'][1..-1]), "Broken link #{link['href']}")
  end
  assert(doc.css('.blog-reference__backlinks a').size == 3, "Return to every mention")
  assert(doc.at_css('cite a')['href'] == 'https://example.org/book?a=1&b=2', "Escaped URLs")
  assert(BlogCitations.render('<p>Uncited.</p>', records, 'test') == '<p>Uncited.</p>', "No empty bibliography")
  rejects("unknown citation") { BlogCitations.render('<p>[@missing]</p>', records, 'test') }

  macro = Liquid::Template.parse('{% cite alpha %}').render!
  assert(macro == '[@alpha]', "Liquid cite macro")
  assert(BlogCitations.render("<p>#{macro}</p>", records, "test").include?('href="#ref-alpha"'), "Macro output")

  File.delete(path)
  bib_path = File.join(directory, 'references.bib')
  File.write(bib_path, bib)
  assert(BlogCitations.load(directory) == records, "Native .bib parity")
  File.write(path, "```bibtex\n@misc{extra, title={Extra source}}\n```\n")
  assert(BlogCitations.load(directory).size == 4, "Combine .md and .bib")
  File.write(path, "```bibtex\n@misc{alpha, title={Duplicate}}\n```\n")
  rejects("duplicate key alpha") { BlogCitations.load(directory) }
  File.delete(path)
  File.write(bib_path, '@article{broken, title = {Unclosed}')
  rejects("Bibliography") { BlogCitations.load(directory) }
  File.write(bib_path, '@misc{empty, author = {Author}}')
  rejects("missing a title") { BlogCitations.load(directory) }
  File.delete(bib_path)
  File.write(path, "# A file without bibliography entries\n")
  rejects("fenced bibtex") { BlogCitations.load(directory) }

  # Build twice to cover separate inputs, RSS rendering and reference-only edits.
  File.delete(path)
  article_dir = File.join(directory, '_blog', 'sample')
  FileUtils.mkdir_p([article_dir, File.join(directory, '_test_layouts')])
  File.write(File.join(article_dir, 'index.md'), "---\nlayout: post\ntitle: Sample\ndate: 2020-01-01\npermalink: /blog/sample/\n---\nFirst [@alpha]. Again [@alpha].\n")
  File.write(File.join(article_dir, 'references.md'), "```bibtex\n#{bib}```\n")
  File.write(File.join(directory, '_test_layouts', 'post.html'), '{{ content | blog_citations: page }}')
  File.write(File.join(directory, 'feed.xml'), "---\nlayout: null\n---\n{% for post in site.blog %}{{ post.content }}{% endfor %}")
  site = Jekyll::Site.new(Jekyll.configuration('source' => directory, 'destination' => File.join(directory, '_site'),
    'collections' => { 'blog' => { 'output' => true } }, 'quiet' => true, 'layouts_dir' => '_test_layouts'))
  Dir.chdir(directory) { site.process }
  output = File.join(directory, '_site', 'blog', 'sample', 'index.html')
  assert(File.read(output).include?('href="#ref-alpha"'), "Full build")
  assert(File.read(File.join(directory, '_site', 'feed.xml')).include?('class="blog-references"'), "RSS references")
  assert(site.collections['blog'].docs.size == 1, "Bibliography is not an article")
  assert(Dir[File.join(directory, '_site', '**', 'references.*')].empty?, "Bibliography source is not published")
  File.write(File.join(article_dir, 'references.md'), "```bibtex\n#{bib.sub('A nested {title}', 'An updated {title}')}```\n")
  Dir.chdir(directory) { site.process }
  assert(File.read(output).include?('An updated title'), "Reference-only edits trigger fresh data")
end

puts "PASS: BibTeX parsing, Markdown/.bib inputs, macros, code literals, numbering, backlinks, validation, builds, RSS and rebuilds"
