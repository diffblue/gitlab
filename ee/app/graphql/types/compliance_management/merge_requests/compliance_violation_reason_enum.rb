# frozen_string_literal: true

module Types
  module ComplianceManagement
    module MergeRequests
      class ComplianceViolationReasonEnum < BaseEnum
        graphql_name 'ComplianceViolationReason'
        description 'Reason for the compliance violation.'

        ::Enums::MergeRequests::ComplianceViolation.reasons.keys.each do |reason|
          value reason.to_s.upcase, value: reason.to_s, description: reason.to_s.humanize
        end
      end
    end
  end
end
