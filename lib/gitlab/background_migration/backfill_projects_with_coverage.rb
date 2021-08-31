# frozen_string_literal: true

# Backfill project_ci_feature_usages for a range of projects with coverage
class Gitlab::BackgroundMigration::BackfillProjectsWithCoverage
  COVERAGE_ENUM_VALUE = 1

  def perform(start_id, end_id)
    ActiveRecord::Base.connection.execute <<~SQL
      INSERT INTO project_ci_feature_usages (project_id, feature, default_branch)
        SELECT DISTINCT project_id, #{COVERAGE_ENUM_VALUE} as feature, default_branch
        FROM ci_daily_build_group_report_results
        WHERE id BETWEEN #{start_id} AND #{end_id}
      ON CONFLICT (project_id, feature, default_branch) DO NOTHING;
    SQL
  end
end
