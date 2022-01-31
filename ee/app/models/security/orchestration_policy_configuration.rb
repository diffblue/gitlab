# frozen_string_literal: true

module Security
  class OrchestrationPolicyConfiguration < ApplicationRecord
    include Security::ScanExecutionPolicy
    include Security::ScanResultPolicy
    include EachBatch
    include Gitlab::Utils::StrongMemoize

    self.table_name = 'security_orchestration_policy_configurations'

    POLICY_PATH = '.gitlab/security-policies/policy.yml'
    POLICY_SCHEMA_PATH = 'ee/app/validators/json_schemas/security_orchestration_policy.json'
    POLICY_SCHEMA = JSONSchemer.schema(Rails.root.join(POLICY_SCHEMA_PATH))
    AVAILABLE_POLICY_TYPES = %i{scan_execution_policy scan_result_policy}.freeze

    belongs_to :project, inverse_of: :security_orchestration_policy_configuration
    belongs_to :security_policy_management_project, class_name: 'Project', foreign_key: 'security_policy_management_project_id'

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

    def policy_hash
      strong_memoize(:policy_hash) do
        next if policy_blob.blank?

        Gitlab::Config::Loader::Yaml.new(policy_blob).load!
      end
    rescue Gitlab::Config::Loader::FormatError
      nil
    end

    def policy_configuration_exists?
      policy_hash.present?
    end

    def policy_configuration_valid?(policy = policy_hash)
      POLICY_SCHEMA.valid?(policy.to_h.deep_stringify_keys)
    end

    def policy_configuration_validation_errors(policy = policy_hash)
      POLICY_SCHEMA
        .validate(policy.to_h.deep_stringify_keys)
        .map { |error| JSONSchemer::Errors.pretty(error) }
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

    def policy_by_type(type)
      return [] if policy_hash.blank?

      policy_hash.fetch(type, [])
    end

    def default_branch_or_main
      security_policy_management_project.default_branch_or_main
    end

    private

    def policy_repo
      security_policy_management_project.repository
    end

    def policy_blob
      strong_memoize(:policy_blob) do
        policy_repo.blob_data_at(default_branch_or_main, POLICY_PATH)
      end
    end
  end
end
