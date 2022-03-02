# frozen_string_literal: true

# This service collects all requirements reports from the CI job and creates a
# series of test report resources, one for each open requirement

module RequirementsManagement
  class ProcessTestReportsService < BaseService
    include Gitlab::Allowable

    def initialize(build)
      @build = build
    end

    def execute
      return unless @build.project.feature_available?(:requirements)
      return if @build.project.issues.requirement.empty?
      return if test_report_already_generated?

      raise Gitlab::Access::AccessDeniedError unless can?(@build.user, :create_requirement_test_report, @build.project)

      RequirementsManagement::TestReport.persist_requirement_reports(@build, report)
    end

    private

    def test_report_already_generated?
      RequirementsManagement::TestReport.for_user_build(@build.user_id, @build.id).exists?
    end

    def report
      ::Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
        @build.collect_requirements_reports!(report)
      end
    end
  end
end
