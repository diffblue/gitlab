# frozen_string_literal: true

module EE
  # AbuseReport EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `AbuseReport` model
  module AbuseReport
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include AfterCommitQueue

      after_create :run_abuse_report_worker
    end

    override :report_type
    def report_type
      return super unless route_hash[:controller] == 'groups/epics'

      :epic
    end

    override :reported_content
    def reported_content
      return super unless report_type == :epic

      group.epics.iid_in(route_hash[:id]).pick(:description_html)
    end

    private

    def run_abuse_report_worker
      run_after_commit_or_now do
        Abuse::NewAbuseReportWorker.perform_async(id)
      end
    end
  end
end
