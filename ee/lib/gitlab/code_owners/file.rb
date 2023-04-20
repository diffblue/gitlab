# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class File
      include ::Gitlab::Utils::StrongMemoize

      # `FNM_DOTMATCH` makes sure we also match files starting with a `.`
      # `FNM_PATHNAME` makes sure ** matches path separators
      FNMATCH_FLAGS = (::File::FNM_DOTMATCH | ::File::FNM_PATHNAME).freeze

      def initialize(blob)
        @blob = blob
        @errors = []
      end

      attr_reader :errors

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

      def entries_for_path(path)
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

      def valid?
        parsed_data

        errors.none?
      end

      private

      def data
        return "" if @blob.nil? || @blob.binary?

        @blob.data
      end

      def get_parsed_data
        current_section = Section.new(name: Section::DEFAULT)
        parsed_sectional_data = {
          current_section.name => {}
        }

        data.lines.each.with_index(1) do |line, line_number|
          line = line.strip

          next if skip?(line)

          section_parser = SectionParser.new(line, parsed_sectional_data)
          parsed_section = section_parser.execute

          # Report errors even if the section is successfully parsed
          unless section_parser.valid?
            section_parser.errors.each { |error| add_error(error, line_number) }
          end

          # Detect section headers and consider next lines in the file as part ot the section.
          if parsed_section
            current_section = parsed_section
            parsed_sectional_data[current_section.name] ||= {}

            next
          end

          parse_entry(line, parsed_sectional_data, current_section, line_number)
        end

        parsed_sectional_data
      end

      def parse_entry(line, parsed, section, line_number)
        pattern, _separator, entry_owners = line.partition(/(?<!\\)\s+/)
        normalized_pattern = normalize_pattern(pattern)

        owners = entry_owners.presence || section.default_owners

        add_error(Error::MISSING_ENTRY_OWNER, line_number) if owners.blank?

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
        ::File.fnmatch?(pattern, path, FNMATCH_FLAGS)
      end

      def add_error(message, line_number)
        errors << Error.new(message: message, line_number: line_number, path: path)
      end
    end
  end
end
