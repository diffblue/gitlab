# frozen_string_literal: true

module Security
  class ScanExecutionPoliciesFinder
    def initialize(actor, object, params = {})
      @actor = actor
      @object = object
      @params = params
    end

    def execute
      policies = fetch_scan_execution_policies
      policies = filter_by_scan_types(policies, params[:action_scan_types]) if params[:action_scan_types]

      policies
    end

    private

    attr_reader :actor, :object, :params

    def fetch_scan_execution_policies
      fetch_policy_configurations
        .select { |config| authorized_to_read_policy_configuration?(config) }
        .flat_map { |config| merge_project_relationship(config) }
    end

    def merge_project_relationship(config)
      config.scan_execution_policy.map do |policy|
        policy.merge(
          config: config,
          project: config.project,
          namespace: config.namespace,
          inherited: config.source != object
        )
      end
    end

    def fetch_policy_configurations
      if params[:relationship] == :inherited
        object.all_security_orchestration_policy_configurations
      else
        Array
          .wrap(policy_configuration)
          .select { |config| config&.policy_configuration_valid? }
      end
    end

    def filter_by_scan_types(policies, scan_types)
      policies.filter do |policy|
        policy_scan_types = policy[:actions].map { |action| action[:scan].to_sym }
        (scan_types & policy_scan_types).present?
      end
    end

    def policy_configuration
      @policy_configuration ||= object.security_orchestration_policy_configuration
    end

    def authorized_to_read_policy_configuration?(config)
      return actor.has_access_to?(policy_configuration.project) if actor.is_a? Clusters::Agent

      Ability.allowed?(actor, :read_security_orchestration_policies, config.security_policy_management_project)
    end
  end
end
