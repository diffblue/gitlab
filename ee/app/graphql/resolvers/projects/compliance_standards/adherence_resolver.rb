# frozen_string_literal: true

module Resolvers
  module Projects
    module ComplianceStandards
      class AdherenceResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource

        alias_method :group, :object

        type ::Types::Projects::ComplianceStandards::AdherenceInputType.connection_type, null: true
        description 'Compliance standards adherence for a project.'

        authorize :read_group_compliance_dashboard
        authorizes_object!

        argument :filters, Types::Projects::ComplianceStandards::AdherenceInputType,
          required: false,
          default_value: {},
          description: 'Filters applied when retrieving compliance standards adherence.'

        def resolve(filters: {})
          ::Projects::ComplianceStandards::AdherenceFinder.new(
            group,
            current_user,
            filters.to_h.merge({ include_subgroups: true })
          ).execute
        end
      end
    end
  end
end
