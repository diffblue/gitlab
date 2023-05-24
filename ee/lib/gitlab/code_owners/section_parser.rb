# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class SectionParser
      REGEX = {
        optional: /(?<optional>\^)?/,
        name: /\[(?<name>.*?)\]/,
        approvals: /(?:\[(?<approvals>\d*?)\])?/,
        default_owners: /(?<default_owners>\s+[@\w_.\-\/\s+]*)?/, # rubocop: disable Style/RegexpLiteralMixedPreserve
        invalid_name: /\[[^\]]+?/
      }.freeze

      HEADER_REGEX = /^#{REGEX.values_at(:optional, :name, :approvals, :default_owners).join}/
      REGEX_INVALID_SECTION = /^#{REGEX.values_at(:optional, :invalid_name).join}$/

      def initialize(line, sectional_data)
        @line = line
        @sectional_data = sectional_data
        @errors = []
      end

      attr_reader :errors

      def execute
        section = fetch_section

        if section.present?
          errors << Error::MISSING_SECTION_NAME if section.name.blank?
          errors << Error::INVALID_APPROVAL_REQUIREMENT if section.optional && section.approvals > 0

          if section.default_owners.present? && ReferenceExtractor.new(section.default_owners).references.blank?
            errors << Error::INVALID_SECTION_OWNER_FORMAT
          end

          return section
        end

        errors << Error::INVALID_SECTION_FORMAT if invalid_section?

        nil
      end

      def valid?
        errors.none?
      end

      private

      attr_reader :line, :sectional_data

      def fetch_section
        match = line.match(HEADER_REGEX)
        return unless match

        Section.new(
          name: find_section_name(match[:name]),
          optional: match[:optional].present?,
          approvals: match[:approvals].to_i,
          default_owners: match[:default_owners]
        )
      end

      def find_section_name(name)
        section_headers = sectional_data.keys

        return name if section_headers.last == Section::DEFAULT

        section_headers.find { |k| k.casecmp?(name) } || name
      end

      def invalid_section?
        line.match?(REGEX_INVALID_SECTION)
      end
    end
  end
end
