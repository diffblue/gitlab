# frozen_string_literal: true

module Resolvers
  class NetworkPolicyResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::NetworkPolicyType, null: true
    authorize :read_threat_monitoring

    argument :environment_id,
             ::Types::GlobalIDType[::Environment],
             required: false,
             description: 'Global ID of the environment to filter policies.'

    alias_method :project, :object

    def resolve(**args)
      authorize!(project)

      result = NetworkPolicies::ResourcesService.new(project: project, environment_id: resolve_gid(args[:environment_id])).execute
      raise Gitlab::Graphql::Errors::BaseError, result.message unless result.success?

      result.payload.map do |policy|
        policy_json = policy.as_json

        {
          name: policy_json[:name],
          kind: policy.resource[:kind],
          namespace: policy_json[:namespace],
          updated_at: Time.iso8601(policy_json[:creation_timestamp]),
          yaml: policy_json[:manifest],
          from_auto_devops: policy_json[:is_autodevops],
          enabled: policy_json[:is_enabled],
          environment_ids: policy_json[:environment_ids],
          project: project
        }
      end
    end

    def resolve_gid(environment_id)
      return if environment_id.blank?

      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      ::Types::GlobalIDType[::Environment]
        .coerce_isolated_input(environment_id)
        .model_id
    end
  end
end
