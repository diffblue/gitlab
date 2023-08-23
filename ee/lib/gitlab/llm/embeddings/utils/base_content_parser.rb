# frozen_string_literal: true

module Gitlab
  module Llm
    module Embeddings
      module Utils
        class BaseContentParser
          attr_reader :max_chars_per_embedding, :min_chars_per_embedding

          def initialize(min_chars_per_embedding, max_chars_per_embedding)
            @max_chars_per_embedding = max_chars_per_embedding
            @min_chars_per_embedding = min_chars_per_embedding
          end

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
            if content.length < max_chars_per_embedding && content.length >= min_chars_per_embedding
              yield content
              return
            end

            positions = content.enum_for(:scan, /\n/).map { Regexp.last_match.begin(0) }

            cursor = 0
            while position = positions.select { |s| s > cursor && s - cursor <= max_chars_per_embedding }.max
              if content[cursor...position].length < min_chars_per_embedding
                cursor = position + 1
                next
              end

              yield content[cursor...position]
              cursor = position + 1
            end

            while cursor < content.length
              content[cursor...].chars.each_slice(max_chars_per_embedding) do |slice|
                if slice.length < min_chars_per_embedding
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
end
