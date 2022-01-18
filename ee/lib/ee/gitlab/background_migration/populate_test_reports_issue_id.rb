# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # Backfills RequirementsManagement::TestReport issue_id column
      # Part of the plan to migrate requirements to work items(issues)
      # More information at: https://gitlab.com/groups/gitlab-org/-/epics/7148
      module PopulateTestReportsIssueId
        def perform(start_id, end_id)
          sql = <<~SQL
            UPDATE requirements_management_test_reports AS test_reports
            SET issue_id = requirements.issue_id
            FROM requirements
            WHERE test_reports.requirement_id = requirements.id
            AND test_reports.issue_id IS NULL
            AND test_reports.id BETWEEN #{start_id} AND #{end_id}
          SQL

          ActiveRecord::Base.connection.execute(sql)

          mark_job_as_succeeded(start_id, end_id)
        end

        private

        def mark_job_as_succeeded(*arguments)
          ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
            self.class.name.demodulize,
            arguments
          )
        end
      end
    end
  end
end
