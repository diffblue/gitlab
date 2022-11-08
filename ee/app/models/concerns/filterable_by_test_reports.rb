# frozen_string_literal: true

module FilterableByTestReports
  extend ActiveSupport::Concern

  included do
    # Used to filter requirements by latest test report state
    scope :include_last_test_report_with_state, -> do
      joins(
        "INNER JOIN LATERAL (
           SELECT state
           FROM requirements_management_test_reports
           WHERE issue_id = #{klass.test_reports_join_column}
           ORDER BY created_at DESC, id DESC LIMIT 1
        ) AS test_reports ON true"
      )
    end

    scope :with_last_test_report_state, -> (state) do
      include_last_test_report_with_state.where(test_reports: { state: state })
    end

    scope :without_test_reports, -> do
      left_joins(:test_reports).where(requirements_management_test_reports: { issue_id: nil })
    end
  end

  class_methods do
    def test_reports_join_column
      raise NotImplementedError
    end
  end
end
