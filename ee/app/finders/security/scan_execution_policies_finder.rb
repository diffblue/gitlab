# frozen_string_literal: true

module Security
  class ScanExecutionPoliciesFinder < ScanPolicyBaseFinder
    def initialize(actor, object, params = {})
      super(actor, object, :scan_execution_policy, params)
    end

    def execute
      policies = fetch_scan_policies
      policies = filter_by_scan_types(policies, params[:action_scan_types]) if params[:action_scan_types]

      policies
    end

    private

    def filter_by_scan_types(policies, scan_types)
      policies.filter do |policy|
        policy_scan_types = policy[:actions].map { |action| action[:scan].to_sym }
        (scan_types & policy_scan_types).present?
      end
    end

    def authorized_to_read_policy_configuration?(config)
      return actor.has_access_to?(project) if actor.is_a?(Clusters::Agent)

      super
    end

    def project
      return unless object.is_a?(Project)

      object
    end
  end
end
