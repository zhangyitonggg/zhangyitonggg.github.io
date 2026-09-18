# frozen_string_literal: true

require "bibtex"
require "latex/decode"
require "nokogiri"
require "cgi"

module BlogCitations
  FILES = %w[references.md references.bib].freeze
  KEY = /\A[A-Za-z0-9][A-Za-z0-9_.:\/+\-]*\z/.freeze
  MARKER = /\[@([^\]\n]+)\]/.freeze
  SKIP = %w[pre code script style textarea a math].freeze

  def self.fail!(source, message)
    raise Jekyll::Errors::FatalException, "Bibliography #{source}: #{message}"
  end

  def self.load(directory)
    sources = FILES.map { |name| File.join(directory, name) }.select { |path| File.file?(path) }
    return {} if sources.empty?

    text = sources.map do |path|
      source = File.read(path, encoding: "UTF-8")
      next source if File.extname(path) == ".bib"

      markdown = Kramdown::Document.new(source, input: "GFM")
      blocks = markdown.root.children.select do |node|
        node.type == :codeblock && %w[bib bibtex].include?(node.options[:lang].to_s.downcase)
      end
      fail!(path, "add a fenced bibtex code block") if blocks.empty?
      blocks.map(&:value).join("\n")
    end.join("\n")

    # BibTeX-Ruby renames duplicate keys by default; reject them explicitly.
    lexer = BibTeX::Lexer.new
    lexer.analyse(text)
    keys = []
    while (token = lexer.next_token)
      break unless token[0]
      next unless token[0] == :KEY
      key = token[1]
      fail!(directory, "invalid key #{key.inspect}") unless KEY.match?(key)
      fail!(directory, "duplicate key #{key}") if keys.include?(key)
      keys << key
    end

    bib = BibTeX.parse(text, allow_missing_keys: false)
    fail!(directory, "invalid BibTeX: #{bib.errors.join('; ')}") if bib.errors?
    fail!(directory, "no BibTeX entries found") if bib.entries.empty?
    bib.replace_strings.join
    bib.entries.each_with_object({}) do |(key, entry), records|
      fields = entry.field_names.each_with_object({}) do |field, result|
        result[field] = LaTeX.decode(entry[field].to_s).strip
      end
      fail!(directory, "#{key} is missing a title") if fields[:title].to_s.empty?
      names = entry[:author] || entry[:editor]
      authors = if names.respond_to?(:map)
                  names.map { |name| LaTeX.decode(name.display_order) }.join(", ")
                else
                  LaTeX.decode(names.to_s)
                end
      volume = fields[:volume].to_s
      volume += "(#{fields[:number]})" unless fields[:number].to_s.empty?
      venue = [fields[:journal] || fields[:booktitle] || fields[:publisher],
               volume, fields[:pages].to_s.gsub("--", "–")].reject { |value| value.to_s.empty? }.join(", ")
      doi = fields[:doi].to_s.sub(%r{\Ahttps?://(?:dx\.)?doi\.org/}i, "")
      url = fields[:url].to_s
      fail!(directory, "#{key} URL must use http or https") unless url.empty? || url.match?(%r{\Ahttps?://}i)
      records[key] = { "title" => fields[:title], "authors" => authors,
                       "year" => fields[:year], "venue" => venue, "doi" => doi, "url" => url }
    end
  rescue BibTeX::ParseError => error
    fail!(directory, error.message)
  end

  def self.escape(text)
    CGI.escapeHTML(text.to_s)
  end

  def self.render(html, records, source, bibliography: true)
    return html unless html.include?("[@")

    document = Nokogiri::HTML.fragment(html)
    order = []
    mentions = Hash.new { |hash, key| hash[key] = [] }
    document.xpath(".//text()").each do |node|
      next unless node.text.include?("[@")
      next if node.ancestors.any? { |ancestor| SKIP.include?(ancestor.name) }

      replacement = +""
      offset = 0
      node.text.to_enum(:scan, MARKER).each do
        match = Regexp.last_match
        replacement << escape(node.text[offset...match.begin(0)])
        keys = match[1].split(";", -1).map { |key| key.strip.sub(/\A@/, "") }
        replacement << keys.map do |key|
          fail!(source, "invalid citation #{match[0]}") unless KEY.match?(key)
          reference = records[key]
          fail!(source, "unknown citation #{key}; add it to references.md or references.bib") unless reference
          order << key unless order.include?(key)
          number = order.index(key) + 1
          id = "cite-#{key}--#{mentions[key].length + 1}"
          mentions[key] << id
          %(<sup class="blog-citation" id="#{escape(id)}"><a href="#ref-#{escape(key)}" role="doc-biblioref" aria-label="Reference #{number}: #{escape(reference['title'])}">[#{number}]</a></sup>)
        end.join
        offset = match.end(0)
      end
      next if offset.zero?
      replacement << escape(node.text[offset..-1])
      node.replace(Nokogiri::HTML.fragment(replacement))
    end
    output = document.to_html
    return output unless bibliography && !order.empty?

    entries = order.map.with_index do |key, index|
      ref = records.fetch(key)
      details = []
      details << "#{escape(ref['authors'].sub(/\.\z/, ''))}." unless ref["authors"].to_s.empty?
      details << "(#{escape(ref['year'])})." unless ref["year"].to_s.empty?
      title = escape(ref["title"])
      title = %(<a href="#{escape(ref['url'])}">#{title}</a>) unless ref["url"].to_s.empty?
      details << "<cite>#{title}</cite>."
      details << "#{escape(ref['venue'])}." unless ref["venue"].to_s.empty?
      unless ref["doi"].to_s.empty?
        details << %(<a class="blog-reference__doi" href="https://doi.org/#{escape(ref['doi'])}">doi:#{escape(ref['doi'])}</a>)
      end
      backlinks = mentions[key].map.with_index do |id, occurrence|
        %(<a href="##{escape(id)}" role="doc-backlink" aria-label="Return to citation #{occurrence + 1} of reference #{index + 1}" title="Return to citation #{occurrence + 1}">↩#{occurrence + 1}</a>)
      end.join
      %(<li id="ref-#{escape(key)}"><div class="blog-reference__entry">#{details.join(' ')} <span class="blog-reference__backlinks">#{backlinks}</span></div></li>)
    end.join("\n")
    output + %(<section class="blog-references" role="doc-bibliography" aria-labelledby="references-heading"><h2 id="references-heading">References</h2><ol>#{entries}</ol></section>)
  end

  module Filters
    def blog_citations(content, page)
      BlogCitations.render(content, page["bibliography_records"] || {}, page["path"])
    end
  end

  # An optional Liquid macro; ordinary Markdown can use [@key] directly.
  class CiteTag < Liquid::Tag
    def initialize(tag, arguments, tokens)
      super
      @key = arguments.strip
      raise Liquid::SyntaxError, "Use {% cite key %}" unless KEY.match?(@key)
    end

    def render(_context)
      "[@#{@key}]"
    end
  end
end

Liquid::Template.register_filter(BlogCitations::Filters)
Liquid::Template.register_tag("cite", BlogCitations::CiteTag)

Jekyll::Hooks.register :site, :post_read do |site|
  collection = site.collections["blog"]
  next unless collection

  # Bibliography files are inputs, not articles or downloadable page assets.
  collection.docs.reject! { |doc| BlogCitations::FILES.include?(File.basename(doc.path)) }
  collection.files.reject! { |file| BlogCitations::FILES.include?(File.basename(file.path)) }
  collection.docs.each do |doc|
    doc.data["bibliography_records"] = BlogCitations.load(File.dirname(doc.path))
  end
end

Jekyll::Hooks.register :documents, :post_render do |doc|
  next unless doc.collection.label == "blog"

  records = doc.data["bibliography_records"] || {}
  # Feed content must contain the same working citations and bibliography.
  doc.content = BlogCitations.render(doc.content, records, doc.path)
  if doc.data["excerpt"]
    doc.data["excerpt"] = BlogCitations.render(doc.data["excerpt"].to_s, records, doc.path, bibliography: false)
  end
end
