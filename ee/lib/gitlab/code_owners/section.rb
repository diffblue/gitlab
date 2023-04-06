# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class Section
      DEFAULT = 'codeowners'

      REGEX = {
        optional: /(?<optional>\^)?/,
        name: /\[(?<name>.*?)\]/,
        approvals: /(?:\[(?<approvals>\d*?)\])?/,
        default_owners: /(?<default_owners>\s+[@\w_.\-\/\s+]*)?/ # rubocop: disable Style/RegexpLiteralMixedPreserve
      }.freeze

      HEADER_REGEX = /^#{REGEX.values_at(:optional, :name, :approvals, :default_owners).join}/

      def self.parse(line, sectional_data)
        match = line.match(HEADER_REGEX)
        return unless match

        new(
          name: find_section_name(match[:name], sectional_data),
          optional: match[:optional].present?,
          approvals: match[:approvals].to_i,
          default_owners: match[:default_owners]
        )
      end

      def self.find_section_name(name, sectional_data)
        section_headers = sectional_data.keys

        return name if section_headers.last == DEFAULT

        section_headers.find { |k| k.casecmp?(name) } || name
      end

      attr_reader :name, :optional, :approvals, :default_owners

      def initialize(name:, optional: false, approvals: 0, default_owners: nil)
        @name = name
        @optional = optional
        @approvals = approvals
        @default_owners = default_owners.to_s.strip
      end
    end
  end
end
