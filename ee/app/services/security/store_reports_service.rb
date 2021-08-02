# frozen_string_literal: true

module Security
  # Service for storing security reports into the database.
  #
  class StoreReportsService < ::BaseService
    def initialize(pipeline)
      @pipeline = pipeline
      @errors = []
    end

    def execute
      set_latest_pipeline!
      mark_project_as_vulnerable!
      store_reports

      errors.any? ? error(full_errors) : success
    end

    private

    attr_reader :pipeline, :errors

    delegate :project, to: :pipeline, private: true

    def store_reports
      pipeline.security_reports.reports.each do |report_type, report|
        result = StoreReportService.new(pipeline, report).execute
        errors << result[:message] if result[:status] == :error
      end
    end

    def mark_project_as_vulnerable!
      project.project_setting.update!(has_vulnerabilities: true)
    end

    def set_latest_pipeline!
      Vulnerabilities::Statistic.set_latest_pipeline_with(pipeline)
    end

    def full_errors
      errors.join(", ")
    end
  end
end
