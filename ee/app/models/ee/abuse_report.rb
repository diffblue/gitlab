# frozen_string_literal: true

module EE
  # AbuseReport EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `AbuseReport` model
  module AbuseReport
    extend ActiveSupport::Concern

    prepended do
      include AfterCommitQueue

      after_create :run_abuse_report_worker
    end

    private

    def run_abuse_report_worker
      run_after_commit_or_now do
        Abuse::NewAbuseReportWorker.perform_async(id)
      end
    end
  end
end
