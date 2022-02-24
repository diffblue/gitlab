# frozen_string_literal: true

module Resolvers
  module ComplianceManagement
    module MergeRequests
      class ComplianceViolationResolver < BaseResolver
        alias_method :group, :object

        type ::Types::ComplianceManagement::MergeRequests::ComplianceViolationType.connection_type, null: true
        description 'Compliance violations reported on a merged merge request.'

        def resolve
          ::ComplianceManagement::MergeRequests::ComplianceViolationsFinder.new(current_user: current_user, group: group).execute
        end
      end
    end
  end
end
