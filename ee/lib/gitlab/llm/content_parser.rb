# frozen_string_literal: true

module Gitlab
  module Llm
    class ContentParser
      include ::Gitlab::Loggable

      MAX_CHARS_PER_EMBEDDING = 1500
      MIN_CHARS_PER_EMBEDDING = 100

      class << self
        def parse_and_split(content, source_name, source_type)
          items = []
          content, metadata, url = parse_content_and_metadata(content, source_name, source_type)
          split_by_newline_positions(content) do |text|
            next if text.nil?
            next unless text.match?(/\w/)

            items << {
              content: text,
              metadata: metadata,
              url: url
            }
          end
          items
        end

        def parse_content_and_metadata(content, source_name, source_type)
          metadata = if content.match?(metadata_regex)
                       metadata = YAML.safe_load(content.match(metadata_regex)[:metadata])
                       content = content.gsub(metadata_regex, '').strip
                       metadata
                     else
                       {}
                     end

          metadata['title'] = title(content)
          metadata['source'] = source_name
          metadata['source_type'] = source_type
          url = url(source_name, source_type)

          [content, metadata, url]
        end

        def split_by_newline_positions(content)
          if content.length < MAX_CHARS_PER_EMBEDDING && content.length >= MIN_CHARS_PER_EMBEDDING
            yield content
            return
          end

          positions = content.enum_for(:scan, /\n/).map { Regexp.last_match.begin(0) }

          cursor = 0
          while position = positions.select { |s| s > cursor && s - cursor <= MAX_CHARS_PER_EMBEDDING }.max
            if content[cursor...position].length < MIN_CHARS_PER_EMBEDDING
              cursor = position + 1
              next
            end

            yield content[cursor...position]
            cursor = position + 1
          end

          while cursor < content.length
            content[cursor...].chars.each_slice(MAX_CHARS_PER_EMBEDDING) do |slice|
              if slice.length < MIN_CHARS_PER_EMBEDDING
                yield nil
                cursor = content.length
                next
              end

              yield slice.join("")
              cursor += slice.length
            end
          end
        end

        def url(source_name, source_type)
          return unless source_name
          return unless source_type == 'doc'

          page = source_name.gsub('/doc/', '').gsub('.md', '')
          ::Gitlab::Routing.url_helpers.help_page_url(page)
        end

        def title(content)
          return unless content

          match = content.match(/#+\s+(?<title>.+)\n/)

          return unless match && match[:title]

          match[:title].gsub(/\*\*\(.+\)\*\*$/, '').strip
        end

        private

        def metadata_regex
          /\A---$\n(?<metadata>(?<anything>[^\n]|\n)+)---$/
        end
      end
    end
  end
end
