# frozen_string_literal: true

module Resolvers
  module ComplianceManagement
    module MergeRequests
      class ComplianceViolationResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource

        alias_method :group, :object

        type ::Types::ComplianceManagement::MergeRequests::ComplianceViolationType.connection_type, null: true
        description 'Compliance violations reported on a merged merge request.'

        authorize :read_group_compliance_dashboard
        authorizes_object!

        argument :filters, Types::ComplianceManagement::MergeRequests::ComplianceViolationInputType,
                 required: false,
                 default_value: {},
                 description: 'Filters applied when retrieving compliance violations.'

        argument :sort, ::Types::ComplianceManagement::MergeRequests::ComplianceViolationSortEnum,
                 required: false,
                 default_value: 'SEVERITY_LEVEL_DESC',
                 description: 'List compliance violations by sort order.'

        def resolve(filters: {}, sort: 'SEVERITY_LEVEL_DESC')
          violations = ::ComplianceManagement::MergeRequests::ComplianceViolationsFinder.new(current_user: current_user, group: group, params: filters.to_h.merge(sort: sort)).execute

          offset_pagination(violations)
        end
      end
    end
  end
end
