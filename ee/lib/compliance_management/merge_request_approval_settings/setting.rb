# frozen_string_literal: true

module ComplianceManagement
  module MergeRequestApprovalSettings
    class Setting
      attr_reader :value, :locked, :inherited_from

      def initialize(value:, locked:, inherited_from:)
        @value = value
        @locked = locked
        @inherited_from = inherited_from
      end
    end
  end
end
