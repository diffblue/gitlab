# frozen_string_literal: true

module Gitlab
  module CodeOwners
    class Error
      INVALID_SECTION_OWNER_FORMAT = :invalid_section_owner_format
      MISSING_ENTRY_OWNER = :missing_entry_owner
      INVALID_ENTRY_OWNER_FORMAT = :invalid_entry_owner_format
      MISSING_SECTION_NAME = :missing_section_name
      INVALID_APPROVAL_REQUIREMENT = :invalid_approval_requirement
      INVALID_SECTION_FORMAT = :invalid_section_format

      def initialize(message:, line_number:, path:)
        @message = message
        @line_number = line_number
        @path = path
      end

      attr_reader :message, :line_number, :path

      def ==(other)
        return true if equal?(other)

        message == other.message &&
          line_number == other.line_number &&
          path == other.path
      end
    end
  end
end
