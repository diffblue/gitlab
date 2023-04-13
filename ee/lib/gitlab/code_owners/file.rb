# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class File
      include ::Gitlab::Utils::StrongMemoize

      def initialize(blob)
        @blob = blob
      end

      def parsed_data
        @parsed_data ||= get_parsed_data
      end

      # Since an otherwise "empty" CODEOWNERS file will still return a default
      #   section of "codeowners", a la
      #
      #   {"codeowners"=>{}}
      #
      #   ...we must cycle through all the actual values parsed into each
      #   section to determine if the file is empty or not.
      #
      def empty?
        parsed_data.values.all?(&:empty?)
      end

      def path
        @blob&.path
      end

      def sections
        parsed_data.keys
      end

      # Check whether any of the entries is optional
      # In cases of the conflicts:
      #
      # [Documentation]
      # *.go @user
      #
      # ^[Documentation]
      # *.rb @user
      #
      # The Documentation section is still required
      def optional_section?(section)
        entries = parsed_data[section]&.values
        entries.present? && entries.all?(&:optional?)
      end

      def entry_for_path(path)
        path = "/#{path}" unless path.start_with?('/')

        matches = []

        parsed_data.each do |_, section_entries|
          matching_pattern = section_entries.keys.reverse.detect do |pattern|
            path_matches?(pattern, path)
          end

          matches << section_entries[matching_pattern].dup if matching_pattern
        end

        matches
      end

      def data
        if @blob && !@blob.binary?
          @blob.data
        else
          ""
        end
      end

      def get_parsed_data
        current_section = Section.new(name: Section::DEFAULT)
        parsed_sectional_data = {
          current_section.name => {}
        }

        data.lines.each do |line|
          line = line.strip

          next if skip?(line)

          # Detect section headers and consider next lines in the file as part ot the section.
          if (parsed_section = Section.parse(line, parsed_sectional_data))
            current_section = parsed_section
            parsed_sectional_data[current_section.name] ||= {}

            next
          end

          parse_entry(line, parsed_sectional_data, current_section)
        end

        parsed_sectional_data
      end

      def parse_entry(line, parsed, section)
        pattern, _separator, entry_owners = line.partition(/(?<!\\)\s+/)
        normalized_pattern = normalize_pattern(pattern)

        owners = entry_owners.presence || section.default_owners

        parsed[section.name][normalized_pattern] = Entry.new(
          pattern,
          owners,
          section.name,
          section.optional,
          section.approvals)
      end

      def skip?(line)
        line.blank? || line.starts_with?('#')
      end

      def normalize_pattern(pattern)
        return '/**/*' if pattern == '*'

        # Remove `\` when escaping `\#`
        pattern = pattern.sub(/\A\\#/, '#')
        # Replace all whitespace preceded by a \ with a regular whitespace
        pattern = pattern.gsub(/\\\s+/, ' ')

        unless pattern.start_with?('/')
          pattern = "/**/#{pattern}"
        end

        if pattern.end_with?('/')
          pattern = "#{pattern}**/*"
        end

        pattern
      end

      def path_matches?(pattern, path)
        # `FNM_DOTMATCH` makes sure we also match files starting with a `.`
        # `FNM_PATHNAME` makes sure ** matches path separators
        flags = ::File::FNM_DOTMATCH | ::File::FNM_PATHNAME

        ::File.fnmatch?(pattern, path, flags)
      end
    end
  end
end
