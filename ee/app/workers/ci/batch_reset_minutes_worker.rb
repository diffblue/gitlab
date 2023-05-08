# frozen_string_literal: true

module Ci
  class BatchResetMinutesWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 10
    feature_category :continuous_integration
    idempotent!

    def perform(from_id, to_id); end
  end
end
