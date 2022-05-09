# frozen_string_literal: true

module ResolvesOrchestrationPolicy
  extend ActiveSupport::Concern

  included do
    include Gitlab::Graphql::Authorize::AuthorizeResource

    calls_gitaly!

    alias_method :project, :object

    private

    def authorize!
      Ability.allowed?(
        context[:current_user], :read_security_orchestration_policies, policy_configuration.security_policy_management_project
      ) || raise_resource_not_available_error!
    end

    def fetch_policy_configurations(relationship)
      if relationship == :inherited
        object.all_security_orchestration_policy_configurations
      else
        Array
          .wrap(policy_configuration)
          .select { |config| config&.policy_configuration_valid? }
      end
    end

    def fetch_scan_execution_policies(relationship)
      fetch_policy_configurations(relationship)
        .select { |config| authorized_to_read_policy_configuration?(config) }
        .flat_map do |config|
          config
            .scan_execution_policy
            .map { |policy| policy.merge(config: config, project: config.project, namespace: config.namespace, inherited: config.source != object) }
        end
    end

    def policy_configuration
      @policy_configuration ||= object.security_orchestration_policy_configuration
    end

    def authorized_to_read_policy_configuration?(config)
      Ability.allowed?(context[:current_user], :read_security_orchestration_policies, config.security_policy_management_project)
    end

    def valid?
      policy_configuration.present? && policy_configuration.policy_configuration_valid?
    end
  end
end
