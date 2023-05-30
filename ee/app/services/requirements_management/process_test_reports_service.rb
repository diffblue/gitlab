# frozen_string_literal: true

# This service collects all requirements reports from the CI job and creates a
# series of test report resources, one for each open requirement

module RequirementsManagement
  class ProcessTestReportsService < BaseService
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    def initialize(build)
      @build = build
    end

    def execute
      return unless @build.project.feature_available?(:requirements)
      return if @build.project.issues.with_issue_type(:requirement).empty?
      return if test_report_already_generated?

      raise Gitlab::Access::AccessDeniedError unless can?(@build.user, :create_requirement_test_report, @build.project)

      # Until old requirement iids are deprecated in favor of work items
      # we keep parsing two kinds of reports to toggle requirements status:
      #
      # 1. Legacy report that uses requirements iids
      # 2. New report that uses work-items iids
      #
      # The first option will be deprecated soon, more information at https://gitlab.com/groups/gitlab-org/-/epics/9203

      # Give preference to new report type that uses work-items iids
      if report.requirements.empty?
        RequirementsManagement::TestReport.persist_requirement_reports(@build, legacy_report, legacy: true)
      else
        RequirementsManagement::TestReport.persist_requirement_reports(@build, report)
      end
    end

    private

    def test_report_already_generated?
      RequirementsManagement::TestReport.for_user_build(@build.user_id, @build.id).exists?
    end

    def legacy_report
      ::Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
        @build.collect_requirements_reports!(report, legacy: true)
      end
    end

    def report
      ::Gitlab::Ci::Reports::RequirementsManagement::Report.new.tap do |report|
        @build.collect_requirements_reports!(report)
      end
    end
    strong_memoize_attr :report
  end
end
