# frozen_string_literal: true

# rubocop: disable Gitlab/ModuleWithInstanceVariables
module EE
  module Gitlab
    module BackgroundMigration
      module MigrateSecurityScans
        extend ::Gitlab::Utils::Override

        override :perform
        def perform(start_id, stop_id)
          # Introduced in GitLab 12.9, will be removed as part of https://gitlab.com/gitlab-org/gitlab/-/issues/33124
          ::Gitlab::Database.allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/331248') do
            execute <<~SQL
              INSERT INTO security_scans (created_at, updated_at, build_id, scan_type)
              SELECT ci_job_artifacts.created_at, ci_job_artifacts.updated_at, ci_job_artifacts.job_id, ci_job_artifacts.file_type - 4
              FROM ci_job_artifacts
              WHERE ci_job_artifacts.id BETWEEN #{start_id} AND #{stop_id}
              AND ci_job_artifacts.file_type BETWEEN 5 and 8
              ON CONFLICT (build_id, scan_type) DO NOTHING;
            SQL
          end
        end

        def execute(sql)
          @connection ||= ::ActiveRecord::Base.connection
          @connection.execute(sql)
        end
      end
    end
  end
end
