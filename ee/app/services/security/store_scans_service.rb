# frozen_string_literal: true

module Security
  class StoreScansService
    def self.execute(pipeline)
      new(pipeline).execute
    end

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      grouped_report_artifacts.each { |artifacts| StoreGroupedScansService.execute(artifacts) }

      schedule_store_reports_worker
    end

    private

    attr_reader :pipeline

    delegate :project, to: :pipeline, private: true

    def grouped_report_artifacts
      pipeline.job_artifacts
              .security_reports
              .group_by(&:file_type)
              .select { |file_type, _| parse_report_file?(file_type) }
              .values
    end

    def parse_report_file?(file_type)
      project.feature_available?(Ci::Build::LICENSED_PARSER_FEATURES.fetch(file_type))
    end

    def schedule_store_reports_worker
      StoreSecurityReportsWorker.perform_async(pipeline.id) if pipeline.default_branch?
    end
  end
end
