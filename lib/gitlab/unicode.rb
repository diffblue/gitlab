# frozen_string_literal: true

module Gitlab
  class Unicode
    # We need to remove "normal" characters from the confusable list
    # as we don't want, for example, 1 to be highlighted.
    #
    # @return [Regexp]
    COMMON_REGEXP = /\p{ASCII}|\p{Emoji}/.freeze

    # Load the Unicode confusables index. This is from the
    # `unicode-confusable` gem, which is a marshalled version of
    # https://unicode.org/Public/security/12.1.0/confusables.txt
    #
    # We remove standard ASCII from this because otherwise it
    # highlights lots of normal characters.
    #
    # We only store the keys as we currently don't actually care
    # about what they could be confused with.
    #
    # @return [Array<Integer>]
    File.open(::Unicode::Confusable::INDEX_FILENAME, "rb") do |file|
      serialized_data = Zlib::GzipReader.new(file).read
      serialized_data.force_encoding Encoding::BINARY

      index = Marshal.load(serialized_data) # rubocop:disable Security/MarshalLoad
      index.reject! { |key, value| key.chr(Encoding::UTF_8).match(COMMON_REGEXP) }

      HOMOGLYPH_INDEX = index.keys.freeze
    end

    # Regular expressions for identifying bidirectional control
    # characters and homoglyphs in UTF-8 strings.
    #
    # Documentation on how some of this works:
    # https://idiosyncratic-ruby.com/41-proper-unicoding.html
    #
    # @return [Hash]
    REGEXP = {
      bidi: /\p{Bidi Control}/,
      homoglyph: Regexp.union(HOMOGLYPH_INDEX.map { |cp| Regexp.new('\u{%x}' % cp) })
    }.freeze

    class << self
      # Process a string for matching characters and highlight them
      #
      # @param string [String] the string to be highlighted
      # @return [String] the highlighted string
      def highlight(string)
        # This is mostly an edgecase caused by specs,
        # and we want to use gsub! for speed.
        string = string.dup if string.frozen?

        REGEXP.each do |type, pattern|
          string.gsub!(pattern) do |char|
            %(<span class="unicode-#{type} has-tooltip" data-toggle="tooltip" title="#{warning(type)}">#{char}</span>)
          end
        end

        string
      end

      private

      # Warning used in tooltips on the GUI
      #
      # @param type [Symbol] a type symbol from the REGEXP hash keys
      # @return [String]
      def warning(type)
        case type
        when :bidi
          _("Potentially unwanted character detected: Unicode BiDi Control")
        when :homoglyph
          _("Potentially unwanted character detected: Unicode Homoglyph")
        end
      end
    end
  end
end
