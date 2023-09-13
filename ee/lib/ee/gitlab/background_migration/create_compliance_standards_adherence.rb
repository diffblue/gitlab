# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # This module is used to create project_compliance_standards_adherence
      # records for ultimate projects not in user namespaces.
      module CreateComplianceStandardsAdherence
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        SUCCESS_STATUS = 0
        FAILED_STATUS = 1
        GITLAB_STANDARD = 0
        PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR = 0
        PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTER = 1
        AT_LEAST_TWO_APPROVALS = 2
        ULTIMATE_PLANS = "'gold', 'ultimate', 'ultimate_trial', 'opensource'"

        prepended do
          operation_name :create_compliance_standards_adherence
        end

        # Migration only version of `application_settings` table
        class ApplicationSetting < ::ApplicationRecord
          self.table_name = 'application_settings'
        end

        # Migration only version of `namespaces` table
        class Namespace < ::ApplicationRecord
          include ::Namespaces::Traversal::Recursive
          include ::Namespaces::Traversal::Linear
          include ::Gitlab::Utils::StrongMemoize
          self.table_name = 'namespaces'
          self.inheritance_column = :_type_disabled
          has_many :projects, class_name: '::EE::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence::Project' # rubocop:disable Layout/LineLength'
          belongs_to :parent, class_name: '::EE::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence::Namespace' # rubocop:disable Layout/LineLength'
        end

        # Migration only version of `namespaces` table
        class Group < ::ApplicationRecord
          self.table_name = 'namespaces'
          self.inheritance_column = :_type_disabled
          has_one :group_merge_request_approval_setting, class_name: '::EE::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence::GroupMergeRequestApprovalSetting' # rubocop:disable Layout/LineLength'
          has_many :projects, class_name: '::EE::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence::Project' # rubocop:disable Layout/LineLength'
        end

        # Migration only version of `group_merge_request_approval_settings` table
        class GroupMergeRequestApprovalSetting < ::ApplicationRecord
          self.table_name = 'group_merge_request_approval_settings'
          belongs_to :group, class_name: '::EE::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence::Group'
        end

        # Migration only version of `projects` table
        class Project < ::ApplicationRecord
          self.table_name = 'projects'
          belongs_to :namespace
          belongs_to :group, -> { where(type: 'Group') }, foreign_key: 'namespace_id', class_name: '::EE::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence::Group' # rubocop:disable Layout/LineLength'
          has_many :approval_rules, class_name: '::EE::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence::ApprovalProjectRule' # rubocop:disable Layout/LineLength

          delegate :root_ancestor, to: :namespace, allow_nil: true
        end

        # Migration only version of `approval_project_rules` table
        class ApprovalProjectRule < ::ApplicationRecord
          self.table_name = 'approval_project_rules'
          belongs_to :project, class_name: '::EE::Gitlab::BackgroundMigration::CreateComplianceStandardsAdherence::Project' # rubocop:disable Layout/LineLength
        end

        override :perform
        def perform
          if ::Gitlab.com?
            ultimate_plan_ids = connection.execute("SELECT id from plans WHERE name IN (#{ULTIMATE_PLANS})")
                                          .values.flatten.join(", ")
          end

          each_sub_batch do |sub_batch|
            Project.id_in(sub_batch).joins(:namespace).includes(:group)
                   .where(namespaces: { type: 'Group' }).each do |project|
              # Don't create compliance_standards_adherence if root group is not on an ultimate plan.
              if ::Gitlab.com?
                root_namespace_plan_query = <<~SQL
                  SELECT 1 AS one FROM gitlab_subscriptions WHERE hosted_plan_id IN (#{ultimate_plan_ids})
                  AND "namespace_id" = #{project.root_ancestor.id} LIMIT 1
                SQL

                result = connection.execute(root_namespace_plan_query)

                next if result.cmd_tuples == 0
              end

              create_prevent_approval_by_author(project)
              create_prevent_approval_by_committer(project)
              create_at_least_two_approvals(project)
            end
          end
        end

        def application_setting
          @application_setting ||= ApplicationSetting.last
        end

        def create_prevent_approval_by_author(project)
          # Logic for calculating the status is copied from `allow_author_approval` method
          # of the ComplianceManagement::MergeRequestApprovalSettings::Resolver module.
          instance_setting = !application_setting.prevent_merge_requests_author_approval
          group_setting = project.group.group_merge_request_approval_setting&.allow_author_approval
          project_setting = project.read_attribute(:merge_requests_author_approval)

          status = [instance_setting, group_setting, project_setting].compact.all? ? FAILED_STATUS : SUCCESS_STATUS

          connection.execute <<~SQL
            INSERT INTO project_compliance_standards_adherence (created_at, updated_at, project_id, namespace_id, status, check_name, standard)
            VALUES (NOW(), NOW(), #{project.id}, #{project.group.id}, #{status}, #{PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR}, #{GITLAB_STANDARD})
            ON CONFLICT (project_id, check_name, standard) DO NOTHING
          SQL
        end

        def create_prevent_approval_by_committer(project)
          # Logic for calculating the status is copied from `allow_committer_approval` method
          # of the ComplianceManagement::MergeRequestApprovalSettings::Resolver module.
          instance_setting = !application_setting.prevent_merge_requests_committers_approval
          group_setting = project.group.group_merge_request_approval_setting&.allow_committer_approval
          project_setting = !project.read_attribute(:merge_requests_disable_committers_approval)

          status = [instance_setting, group_setting, project_setting].compact.all? ? FAILED_STATUS : SUCCESS_STATUS

          connection.execute <<~SQL
            INSERT INTO project_compliance_standards_adherence (created_at, updated_at, project_id, namespace_id, status, check_name, standard)
            VALUES (NOW(), NOW(), #{project.id}, #{project.group.id}, #{status}, #{PREVENT_APPROVAL_BY_MERGE_REQUEST_COMMITTER}, #{GITLAB_STANDARD})
            ON CONFLICT (project_id, check_name, standard) DO NOTHING
          SQL
        end

        def create_at_least_two_approvals(project)
          # Logic for calculating the status is copied from `status method`
          # of the ComplianceManagement::Standards::Gitlab::AtLeastTwoApprovalsService class.
          total_required_approvals = project.approval_rules.pick("SUM(approvals_required)") || 0
          status = total_required_approvals >= 2 ? SUCCESS_STATUS : FAILED_STATUS

          connection.execute <<~SQL
            INSERT INTO project_compliance_standards_adherence (created_at, updated_at, project_id, namespace_id, status, check_name, standard)
            VALUES (NOW(), NOW(), #{project.id}, #{project.group.id}, #{status}, #{AT_LEAST_TWO_APPROVALS}, #{GITLAB_STANDARD})
            ON CONFLICT (project_id, check_name, standard) DO NOTHING
          SQL
        end
      end
    end
  end
end
