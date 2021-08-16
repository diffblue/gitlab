# frozen_string_literal: true

module Security
  class OrchestrationPolicyConfiguration < ApplicationRecord
    include EachBatch
    include Gitlab::Utils::StrongMemoize

    self.table_name = 'security_orchestration_policy_configurations'

    POLICY_PATH = '.gitlab/security-policies/policy.yml'
    POLICY_SCHEMA_PATH = 'ee/app/validators/json_schemas/security_orchestration_policy.json'
    POLICY_LIMIT = 5

    RULE_TYPES = {
      pipeline: 'pipeline',
      schedule: 'schedule'
    }.freeze

    SCAN_TYPES = %w[dast secret_detection].freeze
    ON_DEMAND_SCANS = %w[dast].freeze
    AVAILABLE_POLICY_TYPES = %i{scan_execution_policy}.freeze

    belongs_to :project, inverse_of: :security_orchestration_policy_configuration
    belongs_to :security_policy_management_project, class_name: 'Project', foreign_key: 'security_policy_management_project_id'

    has_many :rule_schedules,
              class_name: 'Security::OrchestrationPolicyRuleSchedule',
              foreign_key: :security_orchestration_policy_configuration_id,
              inverse_of: :security_orchestration_policy_configuration

    validates :project, presence: true, uniqueness: true
    validates :security_policy_management_project, presence: true

    scope :for_project, -> (project_id) { where(project_id: project_id) }
    scope :with_outdated_configuration, -> do
      joins(:security_policy_management_project)
        .where(arel_table[:configured_at].lt(Project.arel_table[:last_repository_updated_at]).or(arel_table[:configured_at].eq(nil)))
    end

    def self.policy_management_project?(project_id)
      self.exists?(security_policy_management_project_id: project_id)
    end

    def self.valid_scan_type?(scan_type)
      SCAN_TYPES.include?(scan_type)
    end

    def enabled?
      ::Feature.enabled?(:security_orchestration_policies_configuration, project)
    end

    def policy_hash
      strong_memoize(:policy_hash) do
        next if policy_blob.blank?

        Gitlab::Config::Loader::Yaml.new(policy_blob).load!
      end
    end

    def policy_configuration_exists?
      policy_hash.present?
    end

    def policy_configuration_valid?(policy = policy_hash)
      JSONSchemer
        .schema(Rails.root.join(POLICY_SCHEMA_PATH))
        .valid?(policy.to_h.deep_stringify_keys)
    end

    def active_policies
      return [] unless enabled?

      scan_execution_policy.select { |config| config[:enabled] }.first(POLICY_LIMIT)
    end

    def on_demand_scan_actions(ref)
      active_policies_scan_actions(ref).select { |action| action[:scan].in?(ON_DEMAND_SCANS) }
    end

    def pipeline_scan_actions(ref)
      active_policies_scan_actions(ref).reject { |action| action[:scan].in?(ON_DEMAND_SCANS) }
    end

    def active_policy_names_with_dast_site_profile(profile_name)
      active_policy_names_with_dast_profiles.dig(:site_profiles, profile_name)
    end

    def active_policy_names_with_dast_scanner_profile(profile_name)
      active_policy_names_with_dast_profiles.dig(:scanner_profiles, profile_name)
    end

    def policy_last_updated_by
      strong_memoize(:policy_last_updated_by) do
        policy_repo.last_commit_for_path(default_branch_or_main, POLICY_PATH)&.author
      end
    end

    def policy_last_updated_at
      strong_memoize(:policy_last_updated_at) do
        policy_repo.last_commit_for_path(default_branch_or_main, POLICY_PATH)&.committed_date
      end
    end

    def delete_all_schedules
      rule_schedules.delete_all(:delete_all)
    end

    def policy_by_type(type)
      return [] if policy_hash.blank?

      policy_hash.fetch(type, [])
    end

    def scan_execution_policy
      policy_by_type(:scan_execution_policy)
    end

    def default_branch_or_main
      security_policy_management_project.default_branch_or_main
    end

    private

    def policy_repo
      security_policy_management_project.repository
    end

    def active_policy_names_with_dast_profiles
      strong_memoize(:active_policy_names_with_dast_profiles) do
        profiles = { site_profiles: Hash.new { Set.new }, scanner_profiles: Hash.new { Set.new } }

        active_policies.each do |policy|
          policy[:actions].each do |action|
            next unless action[:scan].in?(ON_DEMAND_SCANS)

            profiles[:site_profiles][action[:site_profile]] += [policy[:name]]
            profiles[:scanner_profiles][action[:scanner_profile]] += [policy[:name]] if action[:scanner_profile].present?
          end
        end

        profiles
      end
    end

    def active_policies_scan_actions(ref)
      active_policies
        .select { |policy| applicable_for_ref?(policy, ref) }
        .flat_map { |policy| policy[:actions] }
    end

    def policy_blob
      strong_memoize(:policy_blob) do
        policy_repo.blob_data_at(default_branch_or_main, POLICY_PATH)
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
