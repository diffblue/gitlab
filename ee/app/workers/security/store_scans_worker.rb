# frozen_string_literal: true

module Security
  class StoreScansWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include SecurityScansQueue

    tags :exclude_from_kubernetes

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(pipeline_id)
      ::Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
        break unless pipeline.can_store_security_reports?

        record_onboarding_progress(pipeline)

        Security::StoreScansService.execute(pipeline)
      end
    end

    private

    def record_onboarding_progress(pipeline)
      # We only record SAST scans since it's a Free feature and available to all users
      return unless pipeline.security_scans.sast.any?

      OnboardingProgressService.new(pipeline.project.namespace).execute(action: :security_scan_enabled)
    end
  end
end
