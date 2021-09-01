# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill project_ci_feature_usages for a range of projects with coverage
    class BackfillProjectsWithCoverage
      COVERAGE_ENUM_VALUE = 1
      INSERT_DELAY_SECONDS = 0.1

      def perform(start_id, end_id, sub_batch_size)
        report_results = ActiveRecord::Base.connection.execute <<~SQL
          SELECT DISTINCT project_id, default_branch
          FROM ci_daily_build_group_report_results
          WHERE id BETWEEN #{start_id} AND #{end_id}
        SQL

        report_results.to_a.in_groups_of(sub_batch_size, false) do |batch|
          ActiveRecord::Base.connection.execute <<~SQL
            INSERT INTO project_ci_feature_usages (project_id, feature, default_branch) VALUES
            #{build_values(batch)}
            ON CONFLICT (project_id, feature, default_branch) DO NOTHING;
          SQL

          sleep INSERT_DELAY_SECONDS
        end
      end

      private

      def build_values(batch)
        batch.map do |data|
          "(#{data['project_id']}, #{COVERAGE_ENUM_VALUE}, #{data['default_branch']})"
        end.join(', ')
      end
    end
  end
end
