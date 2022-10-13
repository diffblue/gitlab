# frozen_string_literal: true

module Licenses
  class ResetSubmitLicenseUsageDataBannerWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :sticky

    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :sm_provisioning

    # Keep retries within the same day (retries are within ~17 hours)
    sidekiq_options retry: 13

    def perform
      return if License.current.nil?

      Gitlab::Licenses::SubmitLicenseUsageDataBanner.new.reset
    end
  end
end
