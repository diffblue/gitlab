# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module DeleteOrphanedTransferredProjectApprovalRules
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        REPORT_TYPES = {
          license_scanning: 2,
          scan_finding: 4
        }.freeze

        prepended do
          operation_name :delete_all
          scope_to ->(relation) do
            relation.where(report_type: REPORT_TYPES.values)
                    .where.not(security_orchestration_policy_configuration_id: nil)
          end
        end

        class ApprovalProjectRule < ::ApplicationRecord
          include EachBatch
          self.table_name = 'approval_project_rules'

          belongs_to :project
          belongs_to :security_orchestration_policy_configuration, class_name: 'OrchestrationPolicyConfiguration',
            optional: true
        end

        class ApprovalMergeRequestRule < ::ApplicationRecord
          include EachBatch
          self.table_name = 'approval_merge_request_rules'

          belongs_to :merge_request, inverse_of: :approval_rules
          belongs_to :security_orchestration_policy_configuration, class_name: 'OrchestrationPolicyConfiguration',
            optional: true
        end

        class MergeRequest < ::ApplicationRecord
          self.table_name = 'merge_requests'

          has_many :approval_rules, class_name: 'ApprovalMergeRequestRule'
        end

        class Group < ::ApplicationRecord
          self.table_name = 'namespaces'
          self.inheritance_column = :_type_disabled
          include ::Namespaces::Traversal::Recursive

          has_one :security_orchestration_policy_configuration,
            class_name: 'OrchestrationPolicyConfiguration',
            foreign_key: :namespace_id,
            inverse_of: :namespace
        end

        class Project < ::ApplicationRecord
          self.table_name = 'projects'

          has_many :approval_rules, class_name: 'ApprovalProjectRule'
          belongs_to :group, foreign_key: 'namespace_id'
          has_one :security_orchestration_policy_configuration, class_name: 'OrchestrationPolicyConfiguration',
            inverse_of: :project

          def all_security_orchestration_policy_configurations
            all_parent_groups = group&.self_and_ancestor_ids
            return [] if all_parent_groups.blank?

            return Array.wrap(security_orchestration_policy_configuration) if all_parent_groups.blank?

            OrchestrationPolicyConfiguration
                                  .for_project(id)
                                  .or(OrchestrationPolicyConfiguration.for_namespace(all_parent_groups))
          end
        end

        class OrchestrationPolicyConfiguration < ::ApplicationRecord
          self.table_name = 'security_orchestration_policy_configurations'

          scope :for_project, ->(project_id) { where(project_id: project_id) }
          scope :for_namespace, ->(namespace_id) { where(namespace_id: namespace_id) }

          belongs_to :project, inverse_of: :security_orchestration_policy_configuration, optional: true
          has_many :approval_merge_request_rules, -> { where(report_type: REPORT_TYPES.values) },
            foreign_key: 'security_orchestration_policy_configuration_id',
            inverse_of: :security_orchestration_policy_configuration
          has_many :approval_project_rules, -> { where(report_type: REPORT_TYPES.values) },
            foreign_key: 'security_orchestration_policy_configuration_id',
            inverse_of: :security_orchestration_policy_configuration

          def delete_scan_finding_rules_for_project(project_id)
            delete_in_batches(approval_project_rules.where(project_id: project_id))
            delete_in_batches(
              approval_merge_request_rules
                .joins(:merge_request)
                .where(merge_request: { target_project_id: project_id })
            )
          end

          def delete_in_batches(relation)
            relation.each_batch(order_hint: :updated_at) do |batch|
              delete_batch(batch)
            end
          end

          def delete_batch(batch)
            batch.delete_all
          end
        end

        override :perform
        def perform
          each_sub_batch do |sub_batch|
            projects_with_configurations = get_projects_with_configurations(sub_batch)
            projects_with_extra_configurations = get_projects_with_extra_configs(projects_with_configurations)
            resync_mismatched_rules(projects_with_extra_configurations)
          end
        end

        private

        def resync_mismatched_rules(projects_with_missing_configurations)
          projects_with_missing_configurations.each do |project, configuration_ids|
            OrchestrationPolicyConfiguration.where(id: configuration_ids).find_each do |configuration|
              configuration.delete_scan_finding_rules_for_project(project.id)
            end
            process_sync_project_worker.perform_async(project.id) if process_sync_project_worker
          end
        end

        def get_projects_with_extra_configs(projects_with_configurations)
          projects_with_diffs = projects_with_configurations.map do |project, configuration_ids|
            [project, configuration_ids - project.all_security_orchestration_policy_configurations.pluck(:id)]
          end
          projects_with_diffs.select { |_project, configuration_ids| configuration_ids.any? }
        end

        def get_projects_with_configurations(sub_batch)
          ApprovalProjectRule.where(id: sub_batch).joins(:project).includes(:project).group_by(&:project)
                             .map do |project, approval_project_rules|
            [project, approval_project_rules.filter_map(&:security_orchestration_policy_configuration_id).uniq]
          end
        end

        def process_sync_project_worker
          @process_sync_project_worker ||= 'Security::ScanResultPolicies::SyncProjectWorker'.safe_constantize
        end
      end
    end
  end
end
