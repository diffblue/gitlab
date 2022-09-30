# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module PopulateApprovalMergeRequestRulesWithSecurityOrchestration
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          scope_to -> (relation) { relation.where(report_type: 4) }
        end

        override :perform
        def perform
          connection.exec_query(<<~SQL)
            UPDATE approval_merge_request_rules
            SET security_orchestration_policy_configuration_id = ids.security_orchestration_policy_configuration_id
            FROM (SELECT approval_merge_request_rules.id
                  AS approval_merge_request_rules_id,
                  security_orchestration_policy_configurations.id
                  AS security_orchestration_policy_configuration_id
                  FROM approval_merge_request_rules
                  INNER JOIN approval_merge_request_rule_sources
                  ON approval_merge_request_rule_sources.approval_merge_request_rule_id = approval_merge_request_rules.id
                  INNER JOIN approval_project_rules
                  ON approval_merge_request_rule_sources.approval_project_rule_id = approval_project_rules.id
                  INNER JOIN security_orchestration_policy_configurations
                  ON approval_project_rules.project_id = security_orchestration_policy_configurations.project_id
                  WHERE approval_merge_request_rules.report_type = 4
                  AND approval_merge_request_rules.id BETWEEN #{start_id} AND #{end_id}) AS ids
            WHERE approval_merge_request_rules.id = ids.approval_merge_request_rules_id
          SQL
        end
      end
    end
  end
end
