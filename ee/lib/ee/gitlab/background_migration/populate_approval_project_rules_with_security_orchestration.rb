# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module PopulateApprovalProjectRulesWithSecurityOrchestration
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          scope_to -> (relation) { relation.where(report_type: 4) }
        end

        override :perform
        def perform
          connection.exec_query(<<~SQL)
            UPDATE approval_project_rules
            SET security_orchestration_policy_configuration_id = ids.security_orchestration_policy_configurations_id
            FROM (SELECT approval_project_rules.id
                  AS approval_project_rules_id,
                  security_orchestration_policy_configurations.id AS security_orchestration_policy_configurations_id
                  FROM approval_project_rules
                  INNER JOIN security_orchestration_policy_configurations
                  ON security_orchestration_policy_configurations.project_id = approval_project_rules.project_id
                  WHERE approval_project_rules.report_type = 4
                  AND approval_project_rules.id BETWEEN #{start_id} AND #{end_id}) AS ids
            WHERE approval_project_rules.id = ids.approval_project_rules_id
          SQL
        end
      end
    end
  end
end
