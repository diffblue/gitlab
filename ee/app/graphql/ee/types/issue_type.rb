# frozen_string_literal: true

module EE
  module Types
    module IssueType
      extend ActiveSupport::Concern

      prepended do
        field :epic, ::Types::EpicType, null: true, description: 'Epic to which this issue belongs.'

        field :iteration, ::Types::IterationType, null: true, description: 'Iteration of the issue.'

        field :weight, GraphQL::Types::Int, null: true, description: 'Weight of the issue.'

        field :blocked, GraphQL::Types::Boolean, null: false, description: 'Indicates the issue is blocked.'

        field :blocking_count, GraphQL::Types::Int, null: false, method: :blocking_issues_count,
          description: 'Count of issues this issue is blocking.'

        field :blocked_by_count, GraphQL::Types::Int, null: true, description: 'Count of issues blocking this issue.'

        field :blocked_by_issues, ::Types::IssueType.connection_type, null: true, complexity: 5,
          description: 'Issues blocking this issue.'

        field :health_status, ::Types::HealthStatusEnum, null: true, description: 'Current health status.'

        field :status_page_published_incident, GraphQL::Types::Boolean, null: true,
          description: 'Indicates whether an issue is published to the status page.'

        field :sla_due_at, ::Types::TimeType, null: true, description: 'Timestamp of when the issue SLA expires.'

        field :metric_images, [::Types::MetricImageType], null: true,
          description: 'Metric images associated to the issue.'

        field :escalation_policy, ::Types::IncidentManagement::EscalationPolicyType, null: true,
          description: 'Escalation policy associated with the issue. Available for issues which support escalation.'

        field :issuable_resource_links, ::Types::IncidentManagement::IssuableResourceLinkType.connection_type,
          null: true,
          description: 'Issuable resource links of the incident issue.',
          resolver: ::Resolvers::IncidentManagement::IssuableResourceLinksResolver

        def iteration
          ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Iteration, object.sprint_id).find
        end

        def weight
          object.weight_available? ? object.weight : nil
        end

        def blocked
          ::Gitlab::Graphql::Aggregations::Issues::LazyLinksAggregate.new(context, object.id) do |count|
            (count || 0) > 0
          end
        end

        def blocked_by_count
          ::Gitlab::Graphql::Aggregations::Issues::LazyLinksAggregate.new(context, object.id) do |count|
            count || 0
          end
        end

        def blocked_by_issues
          object.blocked_by_issues_for(current_user)
        end

        def health_status
          object.supports_health_status? ? object.health_status : nil
        end

        def escalation_policy
          object.escalation_policies_available? ? object.escalation_status&.policy : nil
        end
      end
    end
  end
end
