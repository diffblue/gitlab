# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module FixApprovalProjectRulesWithoutProtectedBranches
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override
        SCAN_FINDING_REPORT_TYPE = 4

        prepended do
          scope_to ->(relation) do
            relation
              .where(report_type: SCAN_FINDING_REPORT_TYPE)
              .where(applies_to_all_protected_branches: false)
          end
        end

        override :perform
        def perform
          connection.exec_query(<<~SQL)
            UPDATE approval_project_rules
            SET applies_to_all_protected_branches = true
            FROM (SELECT approval_project_rules.id
                  AS approval_project_rules_id
                  FROM approval_project_rules
                  WHERE approval_project_rules.report_type = #{SCAN_FINDING_REPORT_TYPE}
                  AND approval_project_rules.applies_to_all_protected_branches = false
                  AND (NOT EXISTS(SELECT 1 FROM approval_project_rules_protected_branches WHERE approval_project_rules_protected_branches.approval_project_rule_id = approval_project_rules.id))
                  AND approval_project_rules.id BETWEEN #{start_id} AND #{end_id}) AS ids
            WHERE approval_project_rules.id = ids.approval_project_rules_id;
          SQL
        end
      end
    end
  end
end
