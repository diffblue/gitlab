# frozen_string_literal: true

module Security
  class ScanPolicyBaseFinder
    def initialize(actor, object, policy_type, params)
      @actor = actor
      @object = object
      @policy_type = policy_type
      @params = params
    end

    def execute
      raise NotImplementedError
    end

    private

    attr_reader :actor, :object, :policy_type, :params

    def fetch_scan_policies
      fetch_policy_configurations
        .select { |config| authorized_to_read_policy_configuration?(config) }
        .flat_map { |config| merge_project_relationship(config) }
    end

    def policy_configuration
      @policy_configuration ||= object.security_orchestration_policy_configuration
    end

    def authorized_to_read_policy_configuration?(config)
      Ability.allowed?(actor, :read_security_orchestration_policies, config.security_policy_management_project)
    end

    def fetch_policy_configurations
      case params[:relationship]
      when :inherited
        object.all_security_orchestration_policy_configurations
      when :inherited_only
        object.all_inherited_security_orchestration_policy_configurations
      else
        Array
          .wrap(policy_configuration)
          .select { |config| config&.policy_configuration_valid? }
      end
    end

    def merge_project_relationship(config)
      return [] unless config.respond_to? policy_type

      config.public_send(policy_type).map do |policy| # rubocop:disable GitlabSecurity/PublicSend
        policy.merge(
          config: config,
          project: config.project,
          namespace: config.namespace,
          inherited: config.source != object
        )
      end
    end
  end
end
