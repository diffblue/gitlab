# frozen_string_literal: true
module Security
  module ScanExecutionPolicy
    extend ActiveSupport::Concern
    include ::Gitlab::Utils::StrongMemoize

    POLICY_LIMIT = 5

    RULE_TYPES = {
      pipeline: 'pipeline',
      schedule: 'schedule'
    }.freeze

    SCAN_TYPES = %w[dast secret_detection cluster_image_scanning container_scanning sast sast_iac dependency_scanning].freeze
    PIPELINE_SCAN_TYPES = SCAN_TYPES.excluding("cluster_image_scanning").freeze
    ON_DEMAND_SCANS = %w[dast].freeze

    included do
      has_many :rule_schedules,
        class_name: 'Security::OrchestrationPolicyRuleSchedule',
        foreign_key: :security_orchestration_policy_configuration_id,
        inverse_of: :security_orchestration_policy_configuration
    end

    def self.valid_scan_type?(scan_type)
      SCAN_TYPES.include?(scan_type)
    end

    def active_scan_execution_policies
      scan_execution_policy.select { |config| config[:enabled] }.first(POLICY_LIMIT)
    end

    def active_policy_names_with_dast_site_profile(profile_name)
      active_policy_names_with_dast_profiles.dig(:site_profiles, profile_name)
    end

    def active_policy_names_with_dast_scanner_profile(profile_name)
      active_policy_names_with_dast_profiles.dig(:scanner_profiles, profile_name)
    end

    def delete_all_schedules
      rule_schedules.delete_all(:delete_all)
    end

    def scan_execution_policy
      policy_by_type(:scan_execution_policy)
    end

    def active_policies_scan_actions(ref)
      active_scan_execution_policies
        .select { |policy| applicable_for_ref?(policy, ref) }
        .flat_map { |policy| policy[:actions] }
    end

    private

    def active_policy_names_with_dast_profiles
      strong_memoize(:active_policy_names_with_dast_profiles) do
        profiles = { site_profiles: Hash.new { Set.new }, scanner_profiles: Hash.new { Set.new } }

        active_scan_execution_policies.each do |policy|
          policy[:actions].each do |action|
            next unless action[:scan].in?(ON_DEMAND_SCANS)

            profiles[:site_profiles][action[:site_profile]] += [policy[:name]]
            profiles[:scanner_profiles][action[:scanner_profile]] += [policy[:name]] if action[:scanner_profile].present?
          end
        end

        profiles
      end
    end

    def applicable_for_ref?(policy, ref)
      return false unless Gitlab::Git.branch_ref?(ref)

      branch_name = Gitlab::Git.ref_name(ref)

      policy[:rules].any? do |rule|
        rule[:type] == RULE_TYPES[:pipeline] && rule[:branches].any? { |branch| RefMatcher.new(branch).matches?(branch_name) }
      end
    end
  end
end
